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
struct ExerciseDTO: Codable, Identifiable {
    let id: String
    let name: String
    let primaryMuscles: [String]
    let secondaryMuscles: [String]?
    let equipment: String?
    let difficulty: String?
    let movementPattern: String?
    let exerciseType: String?
    let instructions: String?
    let videoUrl: String?
    let thumbnailUrl: String?
    let popularityScore: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case primaryMuscles = "primary_muscles"
        case secondaryMuscles = "secondary_muscles"
        case equipment
        case difficulty
        case movementPattern = "movement_pattern"
        case exerciseType = "exercise_type"
        case instructions
        case videoUrl = "video_url"
        case thumbnailUrl = "thumbnail_url"
        case popularityScore = "popularity_score"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Shared pagination structure
struct PaginationDTO: Codable {
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case total
        case totalPages = "total_pages"
    }
}
