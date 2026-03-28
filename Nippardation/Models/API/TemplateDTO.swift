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
    /// Present on full template payloads; omitted on summary payloads embedded in program responses
    let exercises: [TemplateExerciseDTO]?
    /// Exercise count provided by list endpoints that omit the full exercises array
    let exerciseCount: Int?
    let isPublic: Bool?
    let isAiGenerated: Bool?
    let createdAt: String?
    let updatedAt: String?

    init(id: String, name: String, description: String? = nil, exercises: [TemplateExerciseDTO]? = nil, exerciseCount: Int? = nil, isPublic: Bool? = nil, isAiGenerated: Bool? = nil, createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.exercises = exercises
        self.exerciseCount = exerciseCount
        self.isPublic = isPublic
        self.isAiGenerated = isAiGenerated
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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

}

/// Request body for creating/updating templates
struct TemplateCreateRequest: Codable {
    let name: String
    let description: String?
    let exercises: [TemplateExerciseCreateDTO]
    let isPublic: Bool

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

}
