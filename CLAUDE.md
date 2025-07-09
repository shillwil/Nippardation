# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Nippardation is a native iOS fitness tracking application built with SwiftUI and Core Data. The app allows users to track workouts, exercises, sets, and reps with predefined workout templates inspired by Jeff Nippard's evidence-based training programs.

**Key Features:**
- Real-time workout tracking with persistent state
- 5 predefined workout templates (Pull/Push/Legs hypertrophy, Upper/Lower strength)
- Exercise video demonstrations via YouTube integration
- Volume tracking with multiple unit systems (lbs, kg, pyramid blocks)
- Statistics dashboard with workout history and analytics
- Crash-resistant data persistence with dual-layer caching

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
   - `WorkoutCacheManager.shared`: Provides crash-resistant active workout persistence

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

**Core Data Entities (Completed Workouts):**
- `CDTrackedWorkout`: Workout sessions with metadata (date, duration, template)
- `CDTrackedExercise`: Exercise instances within workouts
- `CDTrackedSet`: Individual sets with reps, weight, and set type

**Swift Models (Active Sessions):**
- `TrackedWorkout`: Active workout state with Codable support for caching
- `TrackedExercise`: Exercise state during active sessions
- `TrackedSet`: Set data with exercise type information

**Template Models (Workout Definitions):**
- `Workout`: Workout template with exercise collection
- `Exercise`: Exercise definition with parameters (sets, reps, rest, intensity techniques)
- `ExerciseType`: Exercise metadata (name, muscle groups)

#### Critical Files for Architecture Understanding

1. **App Lifecycle**: `NippardationApp.swift`
   - Handles app initialization and lifecycle events
   - Ensures data is saved when app backgrounds/terminates
   - Registers custom Core Data transformers

2. **Data Persistence**: `CoreData/CoreDataManager.swift`
   - CRUD operations for workout data
   - Statistics calculations and analytics
   - Background context management
   - Bi-directional conversion between Swift models and Core Data entities

3. **State Management**: `Exercise/WorkoutManager.swift`
   - Central source of truth for workout state
   - Integrates with both cache and Core Data
   - Publishes workout state changes via Combine

4. **Active Workout Caching**: `Exercise/WorkoutCacheManager.swift`
   - Prevents data loss during crashes
   - Auto-save mechanism for active workouts (10-second intervals)
   - JSON-based UserDefaults persistence

### View Architecture

#### Primary Navigation Flow
```
HomeView → WorkoutSelectionView → ActiveWorkoutView → ActiveExerciseDetailView
    ↓                                     ↓
Resume Active Workout              Sheet Presentation
```

#### Key Views
- **HomeView**: Dashboard with workout selection and statistics
- **ActiveWorkoutView**: Real-time workout tracking interface
- **ActiveExerciseDetailView**: Individual exercise tracking with video guidance
- **WorkoutSelectionView**: Modal workout template selection
- **ExercisesListView**: Read-only exercise browsing for templates

#### View Features
- **Adaptive Presentations**: ActiveExerciseDetailView uses multiple presentation detents
- **Real-time Updates**: Views subscribe to WorkoutManager for live data
- **State Persistence**: Active workout state survives app lifecycle events
- **WebView Integration**: YouTube video demonstrations for exercises

### Workout Template System

The app includes 5 predefined workout templates based on Jeff Nippard's programs:

**Hypertrophy Focus:**
- Pull Day (7 exercises): Back, shoulders, biceps
- Push Day (7 exercises): Chest, shoulders, triceps, abs
- Legs (7 exercises): Full lower body including calves

**Strength Focus:**
- Upper (7 exercises): Compound upper body movements
- Lower (6 exercises): Compound lower body movements

**Template Structure:**
- Exercise parameters: warm-up sets, working sets, rep ranges, rest intervals
- Intensity techniques: Failure, Myo-Reps, LLPs (Extended set), Static Stretch
- Video examples: YouTube iframe embeds for form demonstration
- Muscle group targeting: Comprehensive coverage of all major muscle groups

**Data Location**: `Data Files/` directory contains template definitions

### Utility Systems

#### Volume Unit System
- Multiple unit support: pounds, kilograms, pyramid blocks
- Tap-to-cycle functionality for unit conversion
- Consistent conversion factors across the app

#### Helper Classes
- `StringArrayTransformer`: Core Data array persistence
- `WebViewRepresentable`: UIKit WebView integration for SwiftUI
- `IdentifiableIndex`: Wrapper for making array indices identifiable

### Important Patterns and Conventions

1. **File Organization**: Features are grouped by folder (Exercise/, Home/, CoreData/, Models/)
2. **View Naming**: `*View.swift` for SwiftUI views, `*ViewModel.swift` for view models
3. **Navigation**: Uses NavigationStack with sheets and full screen covers
4. **Data Transformers**: Custom `StringArrayTransformer` for storing arrays in Core Data
5. **Error Handling**: Defensive programming with guard statements and optional chaining
6. **Reactive Programming**: Combine framework for data flow and state management

### Working with Active Workouts

The app maintains an active workout session that persists across app launches:
- Check `WorkoutManager.shared.activeWorkout` to see if a workout is in progress
- Use `WorkoutCacheManager.loadCachedWorkout()` to restore interrupted workouts
- Always call `saveActiveWorkout()` after critical changes
- Auto-save occurs every 10 seconds during active sessions

### Data Flow Patterns

**Active Workout Flow:**
```
User Action → View → ViewModel → WorkoutManager → WorkoutCacheManager → UserDefaults
```

**Workout Completion Flow:**
```
End Workout → WorkoutManager → WorkoutCacheManager (complete) → CoreDataManager → Core Data
                                      ↓
                                Clear Cache
```

**Statistics Flow:**
```
HomeView → HomeViewModel → WorkoutManager → CoreDataManager → Core Data Analysis
```

### Testing Approach

The project uses Swift Testing framework (not XCTest). Tests are minimal and located in:
- `NippardationTests/` - Unit tests
- `NippardationUITests/` - UI tests

Use `#expect` syntax for assertions in new tests.