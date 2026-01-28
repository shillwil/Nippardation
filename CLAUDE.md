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

## Workflow Requirements

### Testing Requirements

**ALWAYS run and update tests after making any code changes:**
1. Run the relevant test suite after completing changes
2. Update existing tests if the changes affect their behavior
3. Add new tests for new functionality
4. Ensure all tests pass before offering to commit or push
5. If tests fail, fix the issues before proceeding

```bash
# Run all tests
xcodebuild test -project Nippardation.xcodeproj -scheme Nippardation -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5'

# Run specific test file
xcodebuild test -project Nippardation.xcodeproj -scheme Nippardation -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:NippardationTests/TestClassName
```

### Change Summary Requirements

**ALWAYS provide a comprehensive summary BEFORE pushing to remote.** The summary should be presented to the user for review before executing `git push`. Include:
1. **What was changed**: List all files modified, added, or deleted
2. **Why it was changed**: Explain the problem being solved or feature being added
3. **Broader purpose**: Describe how this change fits into the larger system or goals
4. **Impact**: Note any side effects, breaking changes, or areas that may need attention

Example format:
```
## Summary

**Changes Made:**
- Modified `ExerciseAPIService.swift`: Added network error wrapping
- Created `BaseAPIService.swift`: Extracted shared helper methods

**Why:**
Network errors were not being consistently wrapped in RepositoryError types,
causing inconsistent error handling for callers.

**Broader Purpose:**
This improves the API layer's reliability and maintainability by ensuring
all network operations return consistent error types and reducing code
duplication across service classes.

**Impact:**
- All API services now inherit from BaseAPIService
- No breaking changes to public APIs
- Tests continue to pass without modification
```

**Workflow order:**
1. Make code changes
2. Run tests
3. Stage and commit changes
4. **Present summary to user**
5. Push to remote (only after summary is provided)

## Commit and PR Guidelines

**NEVER include any of the following in commit messages or PR descriptions:**
- "Co-Authored-By: Claude" or any variation
- "Generated by Claude" or "Generated with Claude"
- "AI-generated" or similar AI attribution
- Any footer or signature attributing the code to Claude or AI

Keep commit messages clean and focused on describing the changes made.

# PR Size Requirements - MANDATORY

## Critical Directive: 1000 Line Maximum Per PR

**This is not a guideline. This is a HARD REQUIREMENT.**

Before implementing ANY feature, you MUST create a detailed implementation plan that chunks the work into PRs of 1000 lines or less. NO EXCEPTIONS.

---

## Why This Matters

Large PRs are toxic to code quality:
- Impossible to review comprehensively
- Higher bug escape rate
- Longer review cycles leading to stale code
- Higher chance of merge conflicts
- Slower iteration on feedback
- Difficult to revert if issues found
- AI reviewers cannot effectively analyze >1000 lines in one pass

A 7000-line PR will go through 8+ review cycles finding incremental issues. Seven 1000-line PRs will each complete in 1 cycle. The math is obvious.

---

## Implementation Planning Requirements

Before writing ANY code for a new feature, you must:

### 1. Create Feature Implementation Plan

Document the following:

**Feature Goal**: One-sentence description of what's being built

**Technical Approach**: High-level architecture/design

**PR Breakdown**: List each PR with:
- PR number in sequence (PR1, PR2, etc.)
- Estimated line count
- Specific deliverables
- Dependencies on previous PRs
- User-facing impact (can app run after this PR merges?)

**Example:**
```
Feature: User workout history tracking

Technical Approach: Add Core Data models, repository layer, view models, and UI

PR1: Database schema and models (500 lines)
  - Core Data entities for Workout, Exercise, Set
  - Migrations
  - Unit tests
  Impact: No user-facing changes, app runs normally

PR2: Repository layer (600 lines)
  - WorkoutRepository protocol and implementation
  - CRUD operations
  - Unit tests with mocked persistence
  Impact: No user-facing changes, app runs normally

PR3: ViewModel layer (700 lines)
  - WorkoutHistoryViewModel
  - WorkoutDetailViewModel
  - Combine publishers for state
  - Comprehensive unit tests
  Impact: No user-facing changes, app runs normally

PR4: History list UI (800 lines)
  - SwiftUI views for workout list
  - Navigation setup
  - Empty state, loading state
  - Unit tests for ViewModels
  Impact: New history screen accessible but may be incomplete

PR5: Detail view and editing (900 lines)
  - Workout detail view
  - Edit functionality
  - Delete functionality
  - Unit tests for all interactions
  Impact: Fully functional history feature

Total: ~3500 lines split into 5 PRs, each independently reviewable
```

### 2. Validate Each PR Is Independently Functional

Each PR must leave the app in a working state:
- ✅ App compiles
- ✅ App runs without crashes
- ✅ Tests pass
- ✅ No broken user flows (even if new flow incomplete)
- ✅ No half-implemented features visible to users

**Acceptable**: Feature is incomplete but hidden/inaccessible
**Unacceptable**: Feature is visible but non-functional

### 3. Size Estimation

Be honest about line counts:
- Count tests (they're part of the PR)
- Count generated code if you're writing the generator
- Count new files + modifications to existing files
- Buffer by 20% for unexpected complexity

If your estimate exceeds 1000 lines, split further.

---

## Implementation Rules

### During Development

**Before starting each PR:**
1. Review the implementation plan
2. Confirm the PR scope is still valid
3. Verify estimated line count is achievable
4. Identify any new dependencies

**During coding:**
1. Track line count as you go
2. If approaching 800 lines, evaluate:
   - Can I defer any work to next PR?
   - Am I adding unnecessary complexity?
   - Should I split this PR?

**Before committing:**
1. Count actual lines changed: `git diff --stat main...HEAD`
2. If >1000 lines, STOP:
   - Analyze what can be moved to next PR
   - Create new branch for continuation
   - Cherry-pick or rebase commits to split work
   - Keep current PR under 1000 lines

### Handling Overages

If you realize a PR will exceed 1000 lines:

**Option 1: Pre-emptive Split (Preferred)**
- Identify logical break point in current work
- Complete current PR to break point
- Open PR
- Continue remaining work in new PR

**Option 2: Retrospective Split**
- Finish the work on feature branch
- Create multiple PRs from the commits
- Use `git cherry-pick` or interactive rebase
- Submit PRs sequentially

**Option 3: Rescope**
- Defer non-critical parts to future PR
- Mark as "Phase 2" in implementation plan
- Complete essential parts only

---

## Measurement & Enforcement

### How Line Count Is Calculated

```bash
# Total lines changed (additions + deletions)
git diff --stat main...HEAD | tail -1

# Detailed per-file breakdown
git diff --stat main...HEAD
```

**What counts:**
- All Swift source files
- Test files
- Project configuration changes (if significant)
- Generated code you created
- Asset catalog additions (estimated)

**What doesn't count:**
- Lock files (Package.resolved, Podfile.lock)
- Auto-generated Core Data files
- Third-party dependencies

### Hard Limits

- **Maximum**: 1000 lines changed per PR
- **Target**: 500-800 lines per PR
- **Ideal**: 300-500 lines per PR for complex features

### Exceptions (Rare)

The ONLY acceptable exceptions:
1. **Large refactoring** that touches many files with minimal logic changes
   - Must be pre-approved in implementation plan
   - Must have justification why it can't be split

2. **Generated code** where generator produces >1000 lines
   - Generator itself must be in separate PR
   - Generated output can be single large PR
   - Must include tests proving generation works

3. **Third-party integration** requiring extensive boilerplate
   - Must document why boilerplate can't be incrementalized
   - Must still aim for <1500 lines

**Process for exceptions:**
- Document exception in implementation plan
- Explain why splitting is impractical
- Get explicit approval before proceeding

---

## Quality Gates

Before any PR is opened, verify:

- [ ] Line count < 1000 (run `git diff --stat`)
- [ ] PR is logical unit of work
- [ ] App builds and runs
- [ ] All tests pass
- [ ] No broken user-facing functionality
- [ ] PR description explains what's deliverable
- [ ] Implementation plan updated with actual line count

---

## Multi-Agent Development Considerations

When coordinating multiple agents working in parallel:

### Each Agent Must Work in Stages

**Bad approach:**
```
Agent 1: Implement entire feature X (3000 lines)
Agent 2: Implement entire feature Y (4000 lines)
Result: Two massive PRs that are impossible to review
```

**Good approach:**
```
Agent 1 Stage 1: Feature X foundation (600 lines) → PR1
Agent 2 Stage 1: Feature Y foundation (500 lines) → PR2
Agent 1 Stage 2: Feature X business logic (700 lines) → PR3
Agent 2 Stage 2: Feature Y business logic (800 lines) → PR4
Agent 1 Stage 3: Feature X UI (650 lines) → PR5
Agent 2 Stage 3: Feature Y UI (750 lines) → PR6
```

### Stage Planning Requirements

Each agent's work must be broken into 3-5 stages:
1. **Foundation**: Models, protocols, basic structure
2. **Logic**: Business logic, services, repositories
3. **Integration**: Connecting components, state management
4. **UI**: Views, view models, user-facing features
5. **Polish**: Refinements, edge cases, optimizations

Each stage should target 500-800 lines and result in an independent PR.

### Collision Avoidance

When planning parallel work:
- Identify shared files/modules upfront
- Assign ownership of each file/module
- If agents must touch same file, work sequentially
- Prefer composition over modification
- Use protocols to define boundaries

---

## Consequences of Violation

If a PR exceeds 1000 lines without prior exception approval:

1. **PR will not be reviewed** until split into smaller PRs
2. Implementation plan must be revised
3. Work must be re-chunked and re-submitted

This is not negotiable. Large PRs are a code quality issue that must be prevented, not fixed after the fact.

---

## Success Metrics

A well-planned feature should have:
- ✅ 3-7 PRs of 500-800 lines each
- ✅ Each PR independently reviewable
- ✅ Each PR leaves app in working state
- ✅ Each PR merged within 1 review cycle
- ✅ Feature complete in 1-2 weeks despite multiple PRs

Compare this to:
- ❌ 1 PR of 5000 lines
- ❌ 8+ review cycles finding incremental issues
- ❌ 3-4 weeks to merge
- ❌ High risk of bugs escaping
- ❌ Massive revert if issues found

---

## Remember

**Small PRs are not slower. They're faster.**

You will merge 7 well-crafted 700-line PRs faster than 1 sprawling 5000-line PR. The upfront planning is worth it.

**Code quality depends on reviewability.**

If a human or AI cannot comprehensively review your PR, bugs will slip through. Size is a proxy for reviewability.

**Your PR size reflects your planning quality.**

Large PRs indicate poor feature decomposition. Small, logical PRs indicate thoughtful engineering.

---

## Action Items

Before implementing ANY feature:

1. Write implementation plan with PR breakdown
2. Verify each PR is <1000 lines (estimated)
3. Confirm each PR leaves app functional
4. Get plan reviewed if uncertain
5. Execute plan incrementally
6. Track actual vs estimated line counts
7. Adjust future estimates based on learnings

**This is how professional iOS development works at scale. No shortcuts.**