//
//  ProgramDTO.swift
//  Nippardation
//
//  Phase 0: API Data Transfer Objects for programs
//

import Foundation

/// Response from GET /programs endpoint
struct ProgramListResponse: Codable {
    let programs: [ProgramDTO]
    let pagination: PaginationDTO
}

/// Response from GET /programs/:id, POST /programs, PUT /programs/:id endpoints
struct ProgramDetailResponse: Codable {
    let program: ProgramDTO
}

/// Program data transfer object matching server schema
struct ProgramDTO: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let daysPerWeek: Int
    let durationWeeks: Int?
    let workouts: [ProgramWorkoutDTO]?
    let isActive: Bool?
    let currentDayIndex: Int?
    let timesCompleted: Int?
    let isPublic: Bool?
    let isAiGenerated: Bool?
    let createdAt: String?
    let updatedAt: String?

}

/// Program workout data transfer object
struct ProgramWorkoutDTO: Codable, Identifiable {
    let id: String
    let dayNumber: Int
    let dayLabel: String?
    let templateId: String
    let template: TemplateDTO?

}

/// Request body for creating/updating programs
struct ProgramCreateRequest: Codable {
    let name: String
    let description: String?
    let daysPerWeek: Int
    let durationWeeks: Int?
    let workouts: [ProgramWorkoutCreateDTO]
    let isPublic: Bool

}

/// Program workout for create/update requests
struct ProgramWorkoutCreateDTO: Codable {
    let dayNumber: Int
    let dayLabel: String?
    let templateId: String
}

/// Request body for updating program progress
struct ProgramProgressUpdateRequest: Codable {
    let currentDayIndex: Int
    let timesCompleted: Int?
}
