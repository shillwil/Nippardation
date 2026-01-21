//
//  TemplateDTO.swift
//  Nippardation
//
//  Phase 0: API Data Transfer Objects for templates
//

import Foundation

/// Response from GET /templates endpoint
struct TemplateListResponse: Codable {
    let templates: [TemplateDTO]
    let pagination: PaginationDTO
}

/// Response from GET /templates/:id, POST /templates, PUT /templates/:id endpoints
struct TemplateDetailResponse: Codable {
    let template: TemplateDTO
}

/// Template data transfer object matching server schema
struct TemplateDTO: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let exercises: [TemplateExerciseDTO]
    let isPublic: Bool?
    let isAiGenerated: Bool?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case exercises
        case isPublic = "is_public"
        case isAiGenerated = "is_ai_generated"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Template exercise data transfer object
struct TemplateExerciseDTO: Codable, Identifiable {
    let id: String
    let exerciseId: String
    let exercise: ExerciseDTO?
    let orderIndex: Int
    let warmupSets: Int?
    let workingSets: Int
    let targetReps: String?
    let restSeconds: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exercise_id"
        case exercise
        case orderIndex = "order_index"
        case warmupSets = "warmup_sets"
        case workingSets = "working_sets"
        case targetReps = "target_reps"
        case restSeconds = "rest_seconds"
        case notes
    }
}

/// Request body for creating/updating templates
struct TemplateCreateRequest: Codable {
    let name: String
    let description: String?
    let exercises: [TemplateExerciseCreateDTO]
    let isPublic: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case exercises
        case isPublic = "is_public"
    }
}

/// Template exercise for create/update requests
struct TemplateExerciseCreateDTO: Codable {
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
