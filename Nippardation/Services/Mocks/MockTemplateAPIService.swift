//
//  MockTemplateAPIService.swift
//  Nippardation
//
//  Phase 0 Extension: Mock implementation of TemplateAPIServiceProtocol for testing and development
//

import Foundation

/// Mock implementation of TemplateAPIServiceProtocol for testing and development
final class MockTemplateAPIService: TemplateAPIServiceProtocol, @unchecked Sendable {

    // MARK: - Test Configuration

    var shouldThrowError = false
    var errorToThrow: RepositoryError = .networkUnavailable
    var fetchDelay: TimeInterval = 0.1

    /// Templates to return
    var templateDTOs: [TemplateDTO] = []

    /// If true, deleteTemplate throws conflict error
    var deleteThrowsConflict = false

    // MARK: - Call Tracking

    private(set) var fetchTemplatesCallCount = 0
    private(set) var fetchTemplateCallCount = 0
    private(set) var createTemplateCallCount = 0
    private(set) var updateTemplateCallCount = 0
    private(set) var updateTemplateExercisesCallCount = 0
    private(set) var cloneTemplateCallCount = 0
    private(set) var deleteTemplateCallCount = 0

    private(set) var lastCreateRequest: CreateTemplateRequest?
    private(set) var lastUpdateRequest: UpdateTemplateRequest?
    private(set) var lastExerciseInputs: [TemplateExerciseInput]?

    // MARK: - Initialization

    init() {
        templateDTOs = Self.sampleTemplateDTOs
    }

    // MARK: - Protocol Implementation

    func fetchTemplates(
        cursor: String?,
        limit: Int
    ) async throws -> (templates: [TemplateDTO], pagination: PaginationInfo) {
        fetchTemplatesCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        let startIndex = cursor != nil ? min(Int(cursor!) ?? 0, templateDTOs.count) : 0
        let endIndex = min(startIndex + limit, templateDTOs.count)
        let page = startIndex < templateDTOs.count ? Array(templateDTOs[startIndex..<endIndex]) : []
        let hasMore = endIndex < templateDTOs.count

        return (page, PaginationInfo(nextCursor: hasMore ? String(endIndex) : nil, hasMore: hasMore))
    }

    func fetchTemplate(id: String) async throws -> TemplateDTO {
        fetchTemplateCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        guard let dto = templateDTOs.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        return dto
    }

    func createTemplate(_ request: CreateTemplateRequest) async throws -> TemplateDTO {
        createTemplateCallCount += 1
        lastCreateRequest = request

        if shouldThrowError {
            throw errorToThrow
        }

        let exercises = request.exercises.map { input in
            TemplateExerciseDTO(
                id: UUID().uuidString,
                exerciseId: input.exerciseId,
                exercise: nil,
                orderIndex: input.orderIndex,
                warmupSets: input.warmupSets,
                workingSets: input.workingSets,
                targetReps: input.targetReps,
                restSeconds: input.restSeconds,
                notes: input.notes
            )
        }

        let now = ISO8601DateFormatter().string(from: Date())
        let newDTO = TemplateDTO(
            id: UUID().uuidString,
            name: request.name,
            description: request.description,
            exercises: exercises,
            isPublic: request.isPublic,
            isAiGenerated: false,
            createdAt: now,
            updatedAt: now
        )

        templateDTOs.append(newDTO)
        return newDTO
    }

    func updateTemplate(id: String, _ request: UpdateTemplateRequest) async throws -> TemplateDTO {
        updateTemplateCallCount += 1
        lastUpdateRequest = request

        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = templateDTOs.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        let existing = templateDTOs[index]
        let now = ISO8601DateFormatter().string(from: Date())
        let updated = TemplateDTO(
            id: existing.id,
            name: request.name ?? existing.name,
            description: request.description ?? existing.description,
            exercises: existing.exercises,
            isPublic: existing.isPublic,
            isAiGenerated: existing.isAiGenerated,
            createdAt: existing.createdAt,
            updatedAt: now
        )

        templateDTOs[index] = updated
        return updated
    }

    func updateTemplateExercises(
        id: String,
        _ exercises: [TemplateExerciseInput]
    ) async throws -> TemplateDTO {
        updateTemplateExercisesCallCount += 1
        lastExerciseInputs = exercises

        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = templateDTOs.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        let existing = templateDTOs[index]
        let exerciseDTOs = exercises.map { input in
            TemplateExerciseDTO(
                id: UUID().uuidString,
                exerciseId: input.exerciseId,
                exercise: nil,
                orderIndex: input.orderIndex,
                warmupSets: input.warmupSets,
                workingSets: input.workingSets,
                targetReps: input.targetReps,
                restSeconds: input.restSeconds,
                notes: input.notes
            )
        }

        let now = ISO8601DateFormatter().string(from: Date())
        let updated = TemplateDTO(
            id: existing.id,
            name: existing.name,
            description: existing.description,
            exercises: exerciseDTOs,
            isPublic: existing.isPublic,
            isAiGenerated: existing.isAiGenerated,
            createdAt: existing.createdAt,
            updatedAt: now
        )

        templateDTOs[index] = updated
        return updated
    }

    func cloneTemplate(id: String, newName: String?) async throws -> TemplateDTO {
        cloneTemplateCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        guard let existing = templateDTOs.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        let now = ISO8601DateFormatter().string(from: Date())
        let cloned = TemplateDTO(
            id: UUID().uuidString,
            name: newName ?? "Copy of \(existing.name)",
            description: existing.description,
            exercises: existing.exercises,
            isPublic: false,
            isAiGenerated: false,
            createdAt: now,
            updatedAt: now
        )

        templateDTOs.append(cloned)
        return cloned
    }

    func deleteTemplate(id: String) async throws {
        deleteTemplateCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        if deleteThrowsConflict {
            throw RepositoryError.validationError("Cannot delete template: it is used in one or more programs.")
        }

        templateDTOs.removeAll { $0.id == id }
    }

    /// Reset all tracking state
    func reset() {
        fetchTemplatesCallCount = 0
        fetchTemplateCallCount = 0
        createTemplateCallCount = 0
        updateTemplateCallCount = 0
        updateTemplateExercisesCallCount = 0
        cloneTemplateCallCount = 0
        deleteTemplateCallCount = 0
        lastCreateRequest = nil
        lastUpdateRequest = nil
        lastExerciseInputs = nil
        shouldThrowError = false
        deleteThrowsConflict = false
        templateDTOs = Self.sampleTemplateDTOs
    }
}

// MARK: - Sample Data

extension MockTemplateAPIService {

    static let sampleTemplateDTOs: [TemplateDTO] = [
        TemplateDTO(
            id: "tmpl_001",
            name: "Push Day",
            description: "Chest, shoulders, and triceps",
            exercises: [
                TemplateExerciseDTO(
                    id: "te_001",
                    exerciseId: "ex_001",
                    exercise: nil,
                    orderIndex: 0,
                    warmupSets: 2,
                    workingSets: 4,
                    targetReps: "8-10",
                    restSeconds: 180,
                    notes: nil
                ),
                TemplateExerciseDTO(
                    id: "te_002",
                    exerciseId: "ex_005",
                    exercise: nil,
                    orderIndex: 1,
                    warmupSets: 1,
                    workingSets: 3,
                    targetReps: "12-15",
                    restSeconds: 90,
                    notes: nil
                )
            ],
            isPublic: false,
            isAiGenerated: false,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        ),
        TemplateDTO(
            id: "tmpl_002",
            name: "Pull Day",
            description: "Back and biceps",
            exercises: [
                TemplateExerciseDTO(
                    id: "te_003",
                    exerciseId: "ex_003",
                    exercise: nil,
                    orderIndex: 0,
                    warmupSets: 2,
                    workingSets: 4,
                    targetReps: "5",
                    restSeconds: 240,
                    notes: nil
                ),
                TemplateExerciseDTO(
                    id: "te_004",
                    exerciseId: "ex_004",
                    exercise: nil,
                    orderIndex: 1,
                    warmupSets: 0,
                    workingSets: 3,
                    targetReps: "8-12",
                    restSeconds: 120,
                    notes: nil
                )
            ],
            isPublic: false,
            isAiGenerated: false,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        ),
        TemplateDTO(
            id: "tmpl_003",
            name: "Leg Day",
            description: "Quads, hamstrings, and glutes",
            exercises: [
                TemplateExerciseDTO(
                    id: "te_005",
                    exerciseId: "ex_002",
                    exercise: nil,
                    orderIndex: 0,
                    warmupSets: 3,
                    workingSets: 4,
                    targetReps: "6-8",
                    restSeconds: 240,
                    notes: nil
                ),
                TemplateExerciseDTO(
                    id: "te_006",
                    exerciseId: "ex_009",
                    exercise: nil,
                    orderIndex: 1,
                    warmupSets: 1,
                    workingSets: 3,
                    targetReps: "10-12",
                    restSeconds: 120,
                    notes: nil
                )
            ],
            isPublic: false,
            isAiGenerated: false,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        )
    ]
}
