//
//  SharedAPITypes.swift
//  Nippardation
//
//  Phase 0 Extension: Shared types for API service protocols
//

import Foundation

// MARK: - Pagination

/// Pagination information for cursor-based API responses
struct PaginationInfo: Codable {
    let nextCursor: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

// MARK: - Exercise Filters

/// Filter criteria for API exercise requests
struct ExerciseFilters: Codable {
    let muscleGroups: Set<String>
    let equipment: Set<String>
    let difficulties: Set<String>
    let movementPatterns: Set<String>
    let exerciseTypes: Set<String>
    let searchQuery: String
    let includePrimaryOnly: Bool

    init(
        muscleGroups: Set<String> = [],
        equipment: Set<String> = [],
        difficulties: Set<String> = [],
        movementPatterns: Set<String> = [],
        exerciseTypes: Set<String> = [],
        searchQuery: String = "",
        includePrimaryOnly: Bool = false
    ) {
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.difficulties = difficulties
        self.movementPatterns = movementPatterns
        self.exerciseTypes = exerciseTypes
        self.searchQuery = searchQuery
        self.includePrimaryOnly = includePrimaryOnly
    }

    enum CodingKeys: String, CodingKey {
        case muscleGroups = "muscle_groups"
        case equipment
        case difficulties
        case movementPatterns = "movement_patterns"
        case exerciseTypes = "exercise_types"
        case searchQuery = "search_query"
        case includePrimaryOnly = "include_primary_only"
    }
}

/// Filter options DTO with counts for each filter value
struct ExerciseFilterOptionsDTO: Codable {
    let muscleGroups: [FilterOptionDTO]
    let difficulties: [FilterOptionDTO]
    let equipment: [FilterOptionDTO]
    let movementPatterns: [FilterOptionDTO]
    let exerciseTypes: [FilterOptionDTO]

    enum CodingKeys: String, CodingKey {
        case muscleGroups = "muscle_groups"
        case difficulties
        case equipment
        case movementPatterns = "movement_patterns"
        case exerciseTypes = "exercise_types"
    }
}

/// Individual filter option with label and count
struct FilterOptionDTO: Codable {
    let value: String
    let label: String
    let count: Int
}

// MARK: - Template Request Types

/// Request body for creating templates via API
struct CreateTemplateRequest: Codable {
    let name: String
    let description: String?
    let exercises: [TemplateExerciseInput]
    let isPublic: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case exercises
        case isPublic = "is_public"
    }
}

/// Request body for updating template metadata
struct UpdateTemplateRequest: Codable {
    let name: String?
    let description: String?

    init(name: String? = nil, description: String? = nil) {
        self.name = name
        self.description = description
    }
}

/// Input for template exercises when creating/updating
struct TemplateExerciseInput: Codable {
    let exerciseId: String
    let orderIndex: Int
    let warmupSets: Int?
    let workingSets: Int
    let targetReps: String?
    let restSeconds: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case orderIndex = "order_index"
        case warmupSets = "warmup_sets"
        case workingSets = "working_sets"
        case targetReps = "target_reps"
        case restSeconds = "rest_seconds"
        case notes
    }
}

// MARK: - Program Request Types

/// Request body for creating programs via API
struct CreateProgramRequest: Codable {
    let name: String
    let description: String?
    let daysPerWeek: Int
    let durationWeeks: Int?
    let workouts: [ProgramWorkoutInput]
    let isPublic: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case daysPerWeek = "days_per_week"
        case durationWeeks = "duration_weeks"
        case workouts
        case isPublic = "is_public"
    }
}

/// Request body for updating program metadata
struct UpdateProgramRequest: Codable {
    let name: String?
    let description: String?
    let daysPerWeek: Int?
    let durationWeeks: Int?

    init(
        name: String? = nil,
        description: String? = nil,
        daysPerWeek: Int? = nil,
        durationWeeks: Int? = nil
    ) {
        self.name = name
        self.description = description
        self.daysPerWeek = daysPerWeek
        self.durationWeeks = durationWeeks
    }

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case daysPerWeek = "days_per_week"
        case durationWeeks = "duration_weeks"
    }
}

/// Input for program workouts when creating/updating
struct ProgramWorkoutInput: Codable {
    let dayNumber: Int
    let dayLabel: String?
    let templateId: String

    enum CodingKeys: String, CodingKey {
        case dayNumber = "day_number"
        case dayLabel = "day_label"
        case templateId = "template_id"
    }
}

/// Active program response with next workout info
struct ActiveProgramDTO: Codable {
    let program: ProgramDTO
    let nextWorkout: ProgramWorkoutDTO?
    let isCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case program
        case nextWorkout = "next_workout"
        case isCompleted = "is_completed"
    }
}

/// Summary of a template (used in program workout responses)
struct TemplateSummaryDTO: Codable {
    let id: String
    let name: String
    let description: String?
    let exerciseCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case exerciseCount = "exercise_count"
    }
}

// MARK: - User Types

/// User data transfer object from API
/// Note: All date fields are ISO8601 strings to ensure consistent decoding across all DTOs
struct UserDTO: Codable {
    let id: String
    let firebaseUid: String
    let email: String?
    let handle: String?
    let displayName: String?
    let profilePictureUrl: String?
    let bio: String?
    let height: Double?
    let weight: Double?
    let age: Int?
    let gender: String?
    let unitPreference: String?
    let isPublicProfile: Bool?
    let totalVolumeLiftedLbs: String?
    let totalWorkouts: Int?
    let currentWorkoutStreak: Int?
    let longestWorkoutStreak: Int?
    let lastWorkoutDate: String?
    let pushNotificationTokens: [String]?
    let notificationsEnabled: Bool?
    let lastSyncedAt: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firebaseUid = "firebase_uid"
        case email
        case handle
        case displayName = "display_name"
        case profilePictureUrl = "profile_picture_url"
        case bio
        case height
        case weight
        case age
        case gender
        case unitPreference = "unit_preference"
        case isPublicProfile = "is_public_profile"
        case totalVolumeLiftedLbs = "total_volume_lifted_lbs"
        case totalWorkouts = "total_workouts"
        case currentWorkoutStreak = "current_workout_streak"
        case longestWorkoutStreak = "longest_workout_streak"
        case lastWorkoutDate = "last_workout_date"
        case pushNotificationTokens = "push_notification_tokens"
        case notificationsEnabled = "notifications_enabled"
        case lastSyncedAt = "last_synced_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Request body for updating user profile
struct UpdateUserRequest: Codable {
    let displayName: String?
    let bio: String?
    let height: Double?
    let weight: Double?
    let age: Int?
    let gender: String?
    let unitPreference: String?
    let isPublicProfile: Bool?
    let notificationsEnabled: Bool?

    init(
        displayName: String? = nil,
        bio: String? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        age: Int? = nil,
        gender: String? = nil,
        unitPreference: String? = nil,
        isPublicProfile: Bool? = nil,
        notificationsEnabled: Bool? = nil
    ) {
        self.displayName = displayName
        self.bio = bio
        self.height = height
        self.weight = weight
        self.age = age
        self.gender = gender
        self.unitPreference = unitPreference
        self.isPublicProfile = isPublicProfile
        self.notificationsEnabled = notificationsEnabled
    }

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case bio
        case height
        case weight
        case age
        case gender
        case unitPreference = "unit_preference"
        case isPublicProfile = "is_public_profile"
        case notificationsEnabled = "notifications_enabled"
    }
}

// MARK: - Sync Types

/// Request body for sync endpoint
/// Note: All date fields are ISO8601 strings to ensure consistent decoding across all DTOs
struct SyncRequestDTO: Codable {
    let deviceId: String
    let lastSyncedAt: String?
    let workouts: [WorkoutCreateDTO]

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case lastSyncedAt = "last_synced_at"
        case workouts
    }
}

/// Response from sync endpoint
/// Note: All date fields are ISO8601 strings to ensure consistent decoding across all DTOs
struct SyncResponseDTO: Codable {
    let success: Bool
    let syncedAt: String
    let conflicts: [SyncAPIConflictDTO]?
    let serverData: ServerSyncDataDTO?
    let stats: SyncStatsDTO

    enum CodingKeys: String, CodingKey {
        case success
        case syncedAt = "synced_at"
        case conflicts
        case serverData = "server_data"
        case stats
    }
}

/// Server data from sync (workouts from other devices)
/// Note: All date fields are ISO8601 strings to ensure consistent decoding across all DTOs
struct ServerSyncDataDTO: Codable {
    let workouts: [WorkoutSyncDTO]
    let lastServerSync: String

    enum CodingKeys: String, CodingKey {
        case workouts
        case lastServerSync = "last_server_sync"
    }
}

/// Workout data for sync (subset of full workout)
/// Note: All date fields are ISO8601 strings to ensure consistent decoding across all DTOs
struct WorkoutSyncDTO: Codable {
    let id: String
    let templateName: String?
    let startedAt: String
    let completedAt: String?
    let durationSeconds: Int?
    let exerciseCount: Int
    let totalSets: Int
    let totalVolume: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case templateName = "template_name"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case durationSeconds = "duration_seconds"
        case exerciseCount = "exercise_count"
        case totalSets = "total_sets"
        case totalVolume = "total_volume"
    }
}

/// Sync statistics
struct SyncStatsDTO: Codable {
    let uploaded: Int
    let downloaded: Int
    let conflicts: Int
}

/// Conflict information from sync API
struct SyncAPIConflictDTO: Codable {
    let clientId: String
    let serverId: String?
    let reason: String
    let resolution: String?

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case serverId = "server_id"
        case reason
        case resolution
    }
}
