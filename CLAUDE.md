# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Nippardation is a native iOS fitness tracking application built with SwiftUI and Core Data. The app allows users to track workouts, exercises, sets, and reps with predefined workout templates inspired by Jeff Nippard's training programs.

## Development Commands

### Building
```bash
# Build for simulator
xcodebuild -project Nippardation.xcodeproj -scheme Nippardation -sdk iphonesimulator build

# Build for device
xcodebuild -project Nippardation.xcodeproj -scheme Nippardation -sdk iphoneos build

# Open in Xcode
open Nippardation.xcodeproj
```

### Testing
```bash
# Run unit tests
xcodebuild test -project Nippardation.xcodeproj -scheme Nippardation -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project Nippardation.xcodeproj -scheme NippardationUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Running
```bash
# Run in simulator
xcodebuild -project Nippardation.xcodeproj -scheme Nippardation -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' run
```

## Architecture Overview

### Core Architecture Patterns

1. **MVVM Pattern**: Views communicate with ViewModels that handle business logic
   - Example: `ActiveExerciseDetailView` ↔ `ActiveExerciseViewModel`

2. **Singleton Managers**: Global state management
   - `CoreDataManager.shared`: Handles all Core Data operations
   - `WorkoutManager.shared`: Manages active workout state and completed workouts

3. **Data Persistence Strategy**:
   - **Active Workouts**: Cached to UserDefaults via `WorkoutCacheManager` (auto-saves every 10 seconds)
   - **Completed Workouts**: Persisted to Core Data
   - **Background Saving**: Uses background contexts to prevent UI blocking

### Key Architectural Components

#### State Management Flow
```
User Action → View → ViewModel → Manager → Core Data/Cache
                ↓                    ↓
            UI Update ← Published properties
```

#### Data Models
- **Core Data Entities**: `CDTrackedWorkout`, `CDTrackedExercise`, `CDTrackedSet`
- **Swift Models**: `TrackedWorkout`, `TrackedExercise`, `TrackedSet` (used during active sessions)
- **Template Models**: `Workout`, `Exercise` (predefined workout templates)

#### Critical Files for Architecture Understanding

1. **App Lifecycle**: `NippardationApp.swift`
   - Handles app initialization and lifecycle events
   - Ensures data is saved when app backgrounds/terminates

2. **Data Persistence**: `CoreData/CoreDataManager.swift`
   - CRUD operations for workout data
   - Statistics calculations
   - Background context management

3. **State Management**: `Exercise/WorkoutManager.swift`
   - Central source of truth for workout state
   - Integrates with both cache and Core Data

4. **Active Workout Caching**: `Exercise/WorkoutCacheManager.swift`
   - Prevents data loss during crashes
   - Auto-save mechanism for active workouts

### Important Patterns and Conventions

1. **File Organization**: Features are grouped by folder (Exercise/, Home/, CoreData/)
2. **View Naming**: `*View.swift` for SwiftUI views, `*ViewModel.swift` for view models
3. **Navigation**: Uses NavigationStack with sheets and full screen covers
4. **Data Transformers**: Custom `ArrayTransformer` for storing arrays in Core Data
5. **Error Handling**: Defensive programming with guard statements and optional chaining

### Working with Active Workouts

The app maintains an active workout session that persists across app launches:
- Check `WorkoutManager.shared.activeWorkout` to see if a workout is in progress
- Use `WorkoutCacheManager.loadCachedWorkout()` to restore interrupted workouts
- Always call `saveActiveWorkout()` after critical changes

### Testing Approach

The project uses Swift Testing framework (not XCTest). Tests are minimal and located in:
- `NippardationTests/` - Unit tests
- `NippardationUITests/` - UI tests

Use `#expect` syntax for assertions in new tests.