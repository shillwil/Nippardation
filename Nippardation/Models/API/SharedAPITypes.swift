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

}

/// Filter options DTO with counts for each filter value
struct ExerciseFilterOptionsDTO: Codable {
    let muscleGroups: [FilterOptionDTO]
    let difficulties: [FilterOptionDTO]
    let equipment: [FilterOptionDTO]
    let movementPatterns: [FilterOptionDTO]
    let exerciseTypes: [FilterOptionDTO]

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

}

/// Input for program workouts when creating/updating
struct ProgramWorkoutInput: Codable {
    let dayNumber: Int
    let dayLabel: String?
    let templateId: String

}

/// Active program response with next workout info
struct ActiveProgramDTO: Codable {
    let program: ProgramDTO
    let nextWorkout: ProgramWorkoutDTO?
    let isCompleted: Bool

}

/// Summary of a template (used in program workout responses)
struct TemplateSummaryDTO: Codable {
    let id: String
    let name: String
    let description: String?
    let exerciseCount: Int

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

}

// MARK: - Sync Types

/// Request body for sync endpoint
/// Note: All date fields are ISO8601 strings to ensure consistent decoding across all DTOs
/// Keys are camelCase to match API documentation
struct SyncRequestDTO: Codable {
    let deviceId: String
    let lastSyncTimestamp: String?
    let deviceInfo: SyncDeviceInfo?
    let workouts: [WorkoutCreateDTO]
}

/// Device information included in sync requests
struct SyncDeviceInfo: Codable {
    let name: String?
    let type: String       // "ios"
    let appVersion: String
    let osVersion: String?
}

/// Top-level response wrapper from sync endpoint
struct SyncAPIResponse: Codable {
    let success: Bool
    let message: String?
    let data: SyncResponseDTO
}

/// Inner data from sync endpoint response
/// Note: All date fields are ISO8601 strings to ensure consistent decoding across all DTOs
/// Keys are camelCase to match API documentation
struct SyncResponseDTO: Codable {
    let syncedAt: String
    let conflicts: [SyncAPIConflictDTO]?
    let serverData: ServerSyncDataDTO?
    let stats: SyncStatsDTO?
}

/// Server data from sync (workouts from other devices)
/// Note: All date fields are ISO8601 strings to ensure consistent decoding across all DTOs
struct ServerSyncDataDTO: Codable {
    let workouts: [WorkoutSyncDTO]
    let lastServerSync: String
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

}

/// Sync statistics
struct SyncStatsDTO: Codable {
    let uploaded: Int
    let downloaded: Int
    let conflicts: Int
}

/// Conflict information from sync API
/// Keys are camelCase to match API documentation
struct SyncAPIConflictDTO: Codable {
    let entityType: String
    let entityId: String
    let resolution: String
}
