# Core Data Schema Updates

This document describes the Core Data schema changes needed for backend integration.

## New Entities

### CDExerciseLibrary

Caches exercises from the server.

| Attribute | Type | Notes |
|-----------|------|-------|
| id | UUID | Primary key |
| serverId | String | **Indexed, unique** |
| name | String | |
| primaryMuscles | Transformable [String] | |
| secondaryMuscles | Transformable [String] | |
| equipment | String? | |
| difficulty | String? | |
| movementPattern | String? | |
| exerciseType | String? | |
| instructions | String? | |
| videoUrl | String? | |
| thumbnailUrl | String? | |
| popularityScore | Int32 | |
| lastFetchedAt | Date | For cache invalidation |

### CDTemplate

User's workout templates.

| Attribute | Type | Notes |
|-----------|------|-------|
| id | UUID | Primary key |
| serverId | String | **Indexed, unique** |
| name | String | |
| descriptionText | String? | (Can't use `description`) |
| isPublic | Bool | |
| isAiGenerated | Bool | |
| createdAt | Date | |
| updatedAt | Date | |
| lastFetchedAt | Date | |

**Relationships:**
- `exercises`: To-many → CDTemplateExercise (cascade delete)

### CDTemplateExercise

Exercises within a template.

| Attribute | Type | Notes |
|-----------|------|-------|
| id | UUID | Primary key |
| serverId | String | |
| exerciseServerId | String | Links to CDExerciseLibrary |
| orderIndex | Int16 | |
| warmupSets | Int16 | |
| workingSets | Int16 | |
| targetReps | String? | |
| restSeconds | Int16 | |
| notes | String? | |

**Relationships:**
- `template`: To-one → CDTemplate

### CDProgram

User's workout programs.

| Attribute | Type | Notes |
|-----------|------|-------|
| id | UUID | Primary key |
| serverId | String | **Indexed, unique** |
| name | String | |
| descriptionText | String? | |
| daysPerWeek | Int16 | |
| durationWeeks | Int16 | 0 = indefinite |
| isActive | Bool | **Indexed** |
| currentDayIndex | Int16 | |
| timesCompleted | Int32 | |
| isPublic | Bool | |
| isAiGenerated | Bool | |
| createdAt | Date | |
| updatedAt | Date | |
| lastFetchedAt | Date | |

**Relationships:**
- `workouts`: To-many → CDProgramWorkout (cascade delete)

### CDProgramWorkout

Workouts within a program rotation.

| Attribute | Type | Notes |
|-----------|------|-------|
| id | UUID | Primary key |
| serverId | String | |
| dayNumber | Int16 | |
| dayLabel | String? | |
| templateServerId | String | Links to CDTemplate |

**Relationships:**
- `program`: To-one → CDProgram

### CDVideoCache

Tracks cached videos.

| Attribute | Type | Notes |
|-----------|------|-------|
| id | UUID | Primary key |
| exerciseServerId | String | **Indexed, unique** |
| localPath | String | Path in app documents |
| remoteUrl | String | Original URL |
| fileSize | Int64 | Bytes |
| cachedAt | Date | |
| lastAccessedAt | Date | For LRU eviction |

## Modified Entities

### CDTrackedWorkout (existing)

Add:
| Attribute | Type | Notes |
|-----------|------|-------|
| serverId | String? | **Indexed** |
| syncStatus | Int16 | 0=unsynced, 1=syncing, 2=synced |
| templateServerId | String? | Optional link to template |
| lastSyncedAt | Date? | |

### CDTrackedExercise (existing)

Add:
| Attribute | Type | Notes |
|-----------|------|-------|
| serverId | String? | |
| exerciseLibraryServerId | String? | Links to CDExerciseLibrary |

### CDTrackedSet (existing)

Add:
| Attribute | Type | Notes |
|-----------|------|-------|
| serverId | String? | |

## Migration Notes

1. Create a new model version in Xcode
2. Add new entities and attributes
3. Use lightweight migration (all changes are additive)
4. No data migration code needed

## Index Strategy

Indexes for query performance:

1. `CDExerciseLibrary.serverId` - lookup by server ID
2. `CDTemplate.serverId` - lookup by server ID
3. `CDProgram.serverId` - lookup by server ID
4. `CDProgram.isActive` - find active program
5. `CDTrackedWorkout.serverId` - sync lookups
6. `CDVideoCache.exerciseServerId` - video lookups

## Sync Status Values

```swift
enum SyncStatus: Int16 {
    case unsynced = 0  // Local only, needs upload
    case syncing = 1   // Currently uploading
    case synced = 2    // Matches server
}
```

## Relationship Diagram

```
CDProgram
    │
    │ workouts (1:many)
    ▼
CDProgramWorkout ──────► CDTemplate
                              │
                              │ exercises (1:many)
                              ▼
                        CDTemplateExercise ──────► CDExerciseLibrary
                                                        │
                                                        │ (reference)
                                                        ▼
CDTrackedWorkout ────────────────────────────────► (via serverId)
    │
    │ exercises (1:many)
    ▼
CDTrackedExercise ──────► CDExerciseLibrary
    │                    (via exerciseLibraryServerId)
    │ sets (1:many)
    ▼
CDTrackedSet

CDVideoCache ──────► CDExerciseLibrary
                   (via exerciseServerId)
```
