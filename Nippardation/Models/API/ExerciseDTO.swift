//
//  ExerciseDTO.swift
//  Nippardation
//
//  Phase 0: API Data Transfer Objects for exercises
//

import Foundation

/// Response from GET /exercises endpoint
struct ExerciseListResponse: Codable {
    let exercises: [ExerciseDTO]
    let pagination: PaginationDTO
}

/// Response from GET /exercises/:id endpoint
struct ExerciseDetailResponse: Codable {
    let exercise: ExerciseDTO
}

/// Exercise data transfer object matching server schema
/// Supports both new format (primaryMuscles) and legacy format (muscleGroups)
struct ExerciseDTO: Codable, Identifiable {
    let id: String
    let name: String
    let primaryMuscles: [String]?
    let secondaryMuscles: [String]?
    let equipment: String?
    let difficulty: String?
    let movementPattern: String?
    let exerciseType: String?
    let instructions: String?
    let videoUrl: String?
    let thumbnailUrl: String?
    let popularityScore: Double?
    let createdAt: String?
    let updatedAt: String?
    // Legacy format fields
    let muscleGroups: [String]?
    let isCustom: Bool?
    let createdBy: String?

}

// MARK: - New Format Response Wrappers

/// Response wrapper for the new exercise API format (server returns camelCase keys)
struct ExerciseAPIResponse: Codable {
    let success: Bool
    let data: ExerciseAPIData
    let correlationId: String?
}

/// Data payload in the new exercise API format
struct ExerciseAPIData: Codable {
    let exercises: [ExerciseDTO]
    let pagination: ExerciseAPIPagination
    let meta: ExerciseAPIMeta?
}

/// Pagination in the new exercise API format (server returns camelCase keys)
struct ExerciseAPIPagination: Codable {
    let nextCursor: String?
    let hasMore: Bool
    let page: Int?
    let perPage: Int?
    let total: Int?
    let totalPages: Int?
}

/// Metadata in the new exercise API format (server returns camelCase keys)
struct ExerciseAPIMeta: Codable {
    let searchApplied: Bool?
    let filtersApplied: [String]?
}

// MARK: - Legacy Format Response Wrapper

/// Response wrapper for the legacy exercise API format
struct ExerciseLegacyResponse: Codable {
    let success: Bool
    let data: [ExerciseDTO]
    let pagination: PaginationDTO
}

/// Shared pagination structure
struct PaginationDTO: Codable {
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int

}
