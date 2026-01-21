# Agent Boundaries

This document defines what each parallel development agent owns.

## Phase 0: Tech Lead (COMPLETED)

Created all files in:
- `Models/API/`
- `Models/Domain/`
- `Models/Errors/`
- `Models/Mappers/`
- `Services/Protocols/`
- `Services/Mocks/`
- `Services/DependencyContainer.swift`
- `Services/Utilities/`
- `Documentation/`

## Agent A: Networking/API Layer

**Owns:**
- `Services/API/ExerciseAPIService.swift`
- `Services/API/TemplateAPIService.swift`
- `Services/API/ProgramAPIService.swift`
- `Services/API/SyncAPIService.swift`
- `Services/API/UserAPIService.swift`

**Creates implementations of:**
- Remote operations in `ExerciseRepositoryProtocol`
- Remote operations in `TemplateRepositoryProtocol`
- Remote operations in `ProgramRepositoryProtocol`
- Sync data transformation

**Does NOT touch:**
- Core Data files
- ViewModels
- Views
- `NetworkManager.swift` (uses it, doesn't modify)

## Agent B: Core Data + Local Services

**Owns:**
- `CoreData/CDModel.xcdatamodeld` (schema updates)
- `CoreData/Extensions/CoreDataManager+Exercises.swift`
- `CoreData/Extensions/CoreDataManager+Templates.swift`
- `CoreData/Extensions/CoreDataManager+Programs.swift`
- `CoreData/Extensions/CoreDataManager+VideoCache.swift`
- `Services/Repositories/ExerciseRepository.swift` (combines API + cache)
- `Services/Repositories/TemplateRepository.swift`
- `Services/Repositories/ProgramRepository.swift`
- `Services/Repositories/WorkoutRepository.swift`
- `Services/SyncService.swift`

**Creates implementations of:**
- Full `ExerciseRepositoryProtocol` (API + cache)
- Full `TemplateRepositoryProtocol`
- Full `ProgramRepositoryProtocol`
- Full `WorkoutRepositoryProtocol`
- Full `SyncServiceProtocol`

**Does NOT touch:**
- Views
- ViewModels
- Video player

## Agent C: Video Infrastructure

**Owns:**
- `Services/VideoCache/VideoCacheService.swift`
- `Services/VideoCache/VideoDownloadManager.swift`
- `Views/VideoPlayer/NativeVideoPlayer.swift`
- Modifications to `ActiveExerciseDetailView.swift`
- Modifications to `ActiveExerciseViewModel.swift` (remove WebView logic)

**Creates implementation of:**
- Full `VideoCacheServiceProtocol`

**Does NOT touch:**
- Core Data schema
- API layer
- Other views
- Other ViewModels

## Agent D: ViewModels + Views

**Owns:**
- `ViewModels/DashboardViewModel.swift`
- `ViewModels/ProgramListViewModel.swift`
- `ViewModels/ProgramEditorViewModel.swift`
- `ViewModels/TemplateEditorViewModel.swift`
- `ViewModels/ExerciseBrowserViewModel.swift`
- `Views/Dashboard/DashboardView.swift`
- `Views/Dashboard/WorkoutCarousel.swift`
- `Views/Programs/ProgramListView.swift`
- `Views/Programs/ProgramDetailView.swift`
- `Views/Programs/ProgramEditorView.swift`
- `Views/Templates/TemplateEditorView.swift`
- `Views/Templates/TemplateExerciseRow.swift`
- `Views/Exercises/Browser/ExerciseBrowserView.swift`
- `Views/Exercises/Browser/ExerciseFilterSheet.swift`
- `Views/Exercises/Browser/ExercisePickerRow.swift`

**Uses (via protocols):**
- All repository protocols
- All service protocols

**Does NOT touch:**
- Core Data schema
- API layer implementation
- Video player implementation
- Existing workout tracking views (ActiveWorkoutView, etc.)

## Merge Order

1. Agent A (API layer) - no dependencies
2. Agent B (Core Data) - no dependencies
3. Agent C (Video) - no dependencies
4. Agent D (Views) - after A, B, C merged

Agents A, B, C can merge in any order relative to each other.

## Communication Protocol

When agents need to communicate:

1. **File ownership**: Check this document first
2. **Protocol changes**: Discuss in PR before modifying
3. **Shared models**: Only Tech Lead modifies `Models/`
4. **Conflicts**: Tech Lead resolves

## Testing Responsibilities

- **Agent A**: Unit tests for API services
- **Agent B**: Unit tests for repositories, Core Data
- **Agent C**: Unit tests for video caching
- **Agent D**: Snapshot tests for Views

## Integration Points

### Agent A ↔ Agent B
- Agent A provides `*APIService` classes
- Agent B uses them in repositories

### Agent B ↔ Agent D
- Agent B provides repository implementations
- Agent D uses them via protocols

### Agent C ↔ Agent D
- Agent C provides `VideoCacheService`
- Agent D uses it in exercise detail views

## API Service Layer (Phase 0 Extension)

Phase 0 Extension added API Service Protocols that sit between:
- Agent A (implements the protocols)
- Agent B (consumes the protocols via dependency injection)

### Protocol → Implementation Mapping

| Protocol | Mock (Phase 0) | Real (Agent A) |
|----------|----------------|----------------|
| `ExerciseAPIServiceProtocol` | `MockExerciseAPIService` | `ExerciseAPIService` |
| `TemplateAPIServiceProtocol` | `MockTemplateAPIService` | `TemplateAPIService` |
| `ProgramAPIServiceProtocol` | `MockProgramAPIService` | `ProgramAPIService` |
| `SyncAPIServiceProtocol` | `MockSyncAPIService` | `SyncAPIService` |
| `UserAPIServiceProtocol` | `MockUserAPIService` | `UserAPIService` |

### Why This Matters

Without these protocols, Agent B's repositories would look like:
```swift
// BAD: Direct dependency on Agent A's concrete type
class ExerciseRepository {
    let apiService: ExerciseAPIService // ← Can't compile until Agent A done
}
```

With protocols:
```swift
// GOOD: Depends only on protocol from Phase 0
class ExerciseRepository {
    let apiService: ExerciseAPIServiceProtocol // ← Compiles with mock
}
```

### Agent Responsibilities

**Agent A creates:**
- `Services/API/ExerciseAPIService.swift` implementing `ExerciseAPIServiceProtocol`
- `Services/API/TemplateAPIService.swift` implementing `TemplateAPIServiceProtocol`
- `Services/API/ProgramAPIService.swift` implementing `ProgramAPIServiceProtocol`
- `Services/API/SyncAPIService.swift` implementing `SyncAPIServiceProtocol`
- `Services/API/UserAPIService.swift` implementing `UserAPIServiceProtocol`

**Agent B uses:**
- `ExerciseAPIServiceProtocol` in `ExerciseRepository`
- `TemplateAPIServiceProtocol` in `TemplateRepository`
- `ProgramAPIServiceProtocol` in `ProgramRepository`
- `SyncAPIServiceProtocol` in `SyncService`

Both compile independently. Both can merge in any order.
