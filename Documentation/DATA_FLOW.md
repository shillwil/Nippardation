# Data Flow

This document details the data flow patterns in the Nippardation app.

## Overview

Data flows through the app in a unidirectional pattern:

```
API ─► DTOs ─► Mappers ─► Domain Models ─► ViewModels ─► Views
                             ▲
                             │
                        Core Data
```

## Repository Pattern

Repositories are the single source of truth for data. They:

1. Check cache first
2. Fetch from API if needed
3. Update cache with new data
4. Return domain models

```swift
// Example: ExerciseRepository
func fetchExercises(filter: ExerciseFilter?, forceRefresh: Bool) async throws -> [ExerciseLibraryItem] {
    // 1. Return cached data if not forcing refresh
    if !forceRefresh, let cached = getCachedExercises(filter: filter) {
        return cached
    }

    // 2. Fetch from API
    let response = try await apiService.fetchExercises(filter: filter)

    // 3. Map to domain models
    let exercises = ExerciseMapper.toDomain(response.exercises)

    // 4. Cache for later
    try await cacheExercises(exercises)

    // 5. Return domain models
    return exercises
}
```

## Sync Flow

### Upload Flow (Local → Server)

```
Local Change
    │
    ▼
Save to Core Data (syncStatus = pending)
    │
    ▼
Is Network Available?
    │
    ├─► YES: Attempt sync immediately
    │         │
    │         ├─► Success: Update syncStatus = synced, store serverId
    │         │
    │         └─► Failure: Keep syncStatus = pending, retry later
    │
    └─► NO: Queue for background sync
```

### Download Flow (Server → Local)

```
Fetch from Server
    │
    ▼
Map DTOs to Domain Models
    │
    ▼
For each item:
    │
    ├─► Exists locally?
    │       │
    │       ├─► YES: Check lastSyncedAt vs updatedAt
    │       │         │
    │       │         ├─► Server newer: Update local
    │       │         │
    │       │         └─► Local newer: Mark conflict
    │       │
    │       └─► NO: Insert new record
    │
    ▼
Update lastFetchedAt
```

## Caching Strategy

### Exercise Library
- **Strategy**: Cache-first, background refresh
- **TTL**: 24 hours
- **Storage**: Core Data (CDExerciseLibrary)

```swift
// Always return cache immediately, refresh in background
let cached = getCachedExercises()
if !cached.isEmpty && !forceRefresh {
    Task { try? await refreshInBackground() }
    return cached
}
```

### Templates
- **Strategy**: Write-through cache
- **TTL**: None (always valid until sync)
- **Storage**: Core Data (CDTemplate)

```swift
// Save locally first, sync in background
try await saveToLocalStorage(template)
Task { try? await syncToServer(template) }
```

### Programs
- **Strategy**: Write-through cache
- **TTL**: None (always valid until sync)
- **Storage**: Core Data (CDProgram)

### Workouts
- **Strategy**: Local-first, eventual consistency
- **TTL**: None (permanent local storage)
- **Storage**: Core Data (CDTrackedWorkout)

## Video Cache Flow

```
Request Video
    │
    ▼
Check Local Cache
    │
    ├─► HIT: Return local URL, update lastAccessedAt
    │
    └─► MISS: Download and cache
              │
              ▼
         Check cache size
              │
              ├─► Under limit: Store video
              │
              └─► Over limit: Evict LRU videos, then store
```

## Conflict Resolution

When a sync conflict occurs:

```swift
struct SyncConflict {
    let localVersion: Any
    let remoteVersion: Any
    let detectedAt: Date
}

enum ConflictResolution {
    case keepLocal   // User's changes win
    case keepRemote  // Server's changes win
    case merge       // Future: smart merge
}
```

### Conflict Detection

```
Local Item                 Remote Item
    │                          │
    ▼                          ▼
lastSyncedAt              updatedAt
    │                          │
    └──────► Compare ◄─────────┘
                │
                ▼
    Local modified since last sync?
                │
                ├─► YES + Remote also modified = CONFLICT
                │
                └─► NO = Safe to update
```

## Error Handling Flow

```
API Call
    │
    ▼
NetworkError (low-level)
    │
    ▼
Convert to RepositoryError (user-facing)
    │
    ▼
ViewModel catches error
    │
    ▼
Display appropriate UI
    │
    ├─► networkUnavailable: Show offline banner
    ├─► unauthorized: Trigger re-auth
    ├─► notFound: Remove local item
    ├─► validationError: Show inline errors
    ├─► serverError: Show retry option
    └─► syncConflict: Show conflict resolution UI
```

## Example: Complete Workout Flow

```
User completes workout
    │
    ▼
WorkoutManager.endWorkout()
    │
    ├─► Save to UserDefaults cache (immediate)
    │
    ▼
WorkoutRepository.saveWorkout()
    │
    ├─► Save to Core Data (syncStatus = pending)
    │
    ▼
SyncService.syncWorkout()
    │
    ├─► Network available?
    │       │
    │       ├─► YES: POST to /workouts
    │       │         │
    │       │         ├─► Success: Update syncStatus, store serverId
    │       │         │
    │       │         └─► Failure: Log error, retry on next sync
    │       │
    │       └─► NO: Will sync on next connection
    │
    ▼
Clear UserDefaults cache
```

## Best Practices

1. **Never expose DTOs to Views** - Always map to domain models
2. **Cache aggressively** - Network calls are expensive
3. **Fail gracefully** - Always have fallback data
4. **Sync in background** - Never block UI for sync
5. **Handle conflicts** - Don't lose user data
