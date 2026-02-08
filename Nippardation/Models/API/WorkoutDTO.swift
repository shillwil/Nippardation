//
//  WorkoutDTO.swift
//  Nippardation
//
//  Phase 0: API Data Transfer Objects for workouts (sync)
//

import Foundation

/// Response from GET /workouts endpoint
struct WorkoutListResponse: Codable {
    let workouts: [WorkoutDTO]
    let pagination: PaginationDTO
}

/// Response from GET /workouts/:id, POST /workouts endpoints
struct WorkoutDetailResponse: Codable {
    let workout: WorkoutDTO
}

/// Workout data transfer object for syncing completed workouts
struct WorkoutDTO: Codable, Identifiable {
    let id: String
    let templateId: String?
    let templateName: String?
    let startedAt: String
    let completedAt: String?
    let durationSeconds: Int?
    let notes: String?
    let exercises: [WorkoutExerciseDTO]
    let createdAt: String?
    let updatedAt: String?

}

/// Workout exercise data transfer object
struct WorkoutExerciseDTO: Codable, Identifiable {
    let id: String
    let exerciseId: String?
    let exerciseName: String
    let orderIndex: Int
    let sets: [WorkoutSetDTO]
    let notes: String?

}

/// Workout set data transfer object
struct WorkoutSetDTO: Codable, Identifiable {
    let id: String
    let setNumber: Int
    let setType: String
    let targetReps: Int?
    let completedReps: Int?
    let weight: Double?
    let weightUnit: String?
    let rpe: Double?
    let notes: String?

}

/// Request body for syncing workouts
struct WorkoutSyncRequest: Codable {
    let workouts: [WorkoutCreateDTO]
}

/// Workout for create/sync requests (camelCase keys match API sync schema)
struct WorkoutCreateDTO: Codable {
    let clientId: String
    let userId: String
    let date: String
    let name: String?
    let templateName: String?
    let startTime: String
    let endTime: String?
    let durationSeconds: Int?
    let isCompleted: Bool
    let updatedAt: String
    let exercises: [WorkoutExerciseCreateDTO]
}

/// Workout exercise for create requests (camelCase keys match API sync schema)
struct WorkoutExerciseCreateDTO: Codable {
    let clientId: String
    let exerciseName: String
    let muscleGroups: [String]
    let sets: [WorkoutSetCreateDTO]
    let updatedAt: String
}

/// Workout set for create requests (camelCase keys match API sync schema)
struct WorkoutSetCreateDTO: Codable {
    let clientId: String
    let setType: String
    let reps: Int?
    let weight: Double?
    let exerciseTypeName: String
    let exerciseTypeMuscleGroups: [String]
    let updatedAt: String
}

/// Response from workout sync endpoint with server IDs mapped to client IDs
struct WorkoutSyncResponseDTO: Codable {
    let synced: [SyncedItemDTO]
    let conflicts: [SyncConflictDTO]?
}

/// Mapping of client ID to server ID after sync
struct SyncedItemDTO: Codable {
    let clientId: String
    let serverId: String
}

/// Conflict information when sync fails for an item
struct SyncConflictDTO: Codable {
    let clientId: String
    let reason: String
    let serverVersion: WorkoutDTO?
}
