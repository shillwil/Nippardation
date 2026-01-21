# Architecture Overview

This document describes the architecture for backend integration in Nippardation.

## Layer Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         Views                                │
│  (SwiftUI views that display data and handle user input)    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       ViewModels                             │
│  (Coordinate between Views and Repositories)                 │
│  - Handle UI state and logic                                 │
│  - Transform domain models for display                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Repositories                            │
│  (Single source of truth for data)                          │
│  - Coordinate between API and local storage                 │
│  - Handle caching strategy                                   │
│  - Expose domain models                                      │
└─────────────────────────────────────────────────────────────┘
                    │                   │
                    ▼                   ▼
┌──────────────────────────┐  ┌──────────────────────────────┐
│      API Services        │  │     Local Storage            │
│  (Network calls)         │  │  (Core Data + Cache)         │
│  - REST endpoints        │  │  - Persistent storage        │
│  - DTO mapping           │  │  - UserDefaults cache        │
└──────────────────────────┘  └──────────────────────────────┘
```

## Key Components

### 1. Models

**API Models (DTOs)**
- Located in `Models/API/`
- Mirror server JSON structure exactly
- Use snake_case CodingKeys to match API
- Never used directly in Views

**Domain Models**
- Located in `Models/Domain/`
- Used throughout the app
- Designed for UI consumption
- Include computed properties for display

**Mappers**
- Located in `Models/Mappers/`
- Convert between DTOs and domain models
- Handle data transformation and validation

### 2. Services

**Protocols**
- Located in `Services/Protocols/`
- Define contracts for all services
- Enable dependency injection and testing

**Repositories**
- Will be located in `Services/Repositories/`
- Combine API + local storage
- Implement caching strategies
- Handle offline support

**API Services**
- Will be located in `Services/API/`
- Make HTTP requests
- Parse responses into DTOs
- Handle authentication headers

### 3. Dependency Injection

The `DependencyContainer` provides:
- Protocol-based service access
- Easy swapping for tests
- Preview support with mock data

```swift
// In production
DependencyContainer.shared.configureForProduction()

// In tests/previews
DependencyContainer.shared.configureForTesting()
```

## Data Flow

### Reading Data

```
View.onAppear
    │
    ▼
ViewModel.loadData()
    │
    ▼
Repository.fetch(forceRefresh: false)
    │
    ├─► Return cached data immediately (if available)
    │
    ▼
API.fetch()
    │
    ▼
Mapper.toDomain()
    │
    ▼
Cache.save()
    │
    ▼
ViewModel.data = result
    │
    ▼
View updates via @Published
```

### Writing Data

```
View action (button tap)
    │
    ▼
ViewModel.save()
    │
    ▼
Repository.create/update()
    │
    ├─► Cache.save() (immediate local persistence)
    │
    ▼
API.post/put() (async, can fail)
    │
    ├─► If online: sync immediately
    │
    └─► If offline: queue for later sync
```

## Error Handling

All errors are converted to `RepositoryError` before reaching ViewModels:

```swift
enum RepositoryError {
    case networkUnavailable  // No connection
    case unauthorized        // Needs re-auth
    case notFound           // 404
    case validationError    // Invalid input
    case serverError        // 5xx
    case syncConflict       // Version mismatch
}
```

ViewModels handle errors appropriately:
- Show user-friendly messages
- Trigger re-authentication when needed
- Offer retry for transient failures

## Offline Support

1. **Exercises**: Read-only cache, fetched on demand
2. **Templates**: Full offline CRUD, syncs when online
3. **Programs**: Full offline CRUD, syncs when online
4. **Workouts**: Always saved locally first, synced later

## Testing

Each layer is testable independently:

- **Views**: Use preview containers with mock data
- **ViewModels**: Inject mock repositories
- **Repositories**: Inject mock API services
- **API Services**: Use URLProtocol mock

## Adding New Features

1. Add DTO in `Models/API/`
2. Add domain model in `Models/Domain/`
3. Add mapper in `Models/Mappers/`
4. Add protocol in `Services/Protocols/`
5. Add mock in `Services/Mocks/`
6. Implement repository
7. Create ViewModel and View
