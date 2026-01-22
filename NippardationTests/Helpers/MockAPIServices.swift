//
//  MockAPIServices.swift
//  NippardationTests
//
//  Mock API services for testing repositories
//

import Foundation
@testable import Nippardation

// MARK: - Mock Exercise API Service

actor MockExerciseAPIService: ExerciseAPIServiceProtocol {

    var exercises: [ExerciseDTO] = []
    var filterOptions: ExerciseFilterOptionsDTO?
    var shouldFail = false
    var failureError: Error = RepositoryError.networkUnavailable

    func fetchExercises(
        filters: ExerciseFilters?,
        cursor: String?,
        limit: Int
    ) async throws -> (exercises: [ExerciseDTO], pagination: PaginationInfo) {
        if shouldFail { throw failureError }

        var filtered = exercises

        if let searchQuery = filters?.searchQuery, !searchQuery.isEmpty {
            filtered = filtered.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
        }

        // Filter by muscle groups
        if let muscleGroups = filters?.muscleGroups, !muscleGroups.isEmpty {
            filtered = filtered.filter { exercise in
                !muscleGroups.isDisjoint(with: Set(exercise.primaryMuscles))
            }
        }

        let pagination = PaginationInfo(
            nextCursor: nil,
            hasMore: false
        )

        return (filtered, pagination)
    }

    func fetchExercise(id: String) async throws -> ExerciseDTO {
        if shouldFail { throw failureError }

        guard let exercise = exercises.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return exercise
    }

    func fetchFilterOptions() async throws -> ExerciseFilterOptionsDTO {
        if shouldFail { throw failureError }

        return filterOptions ?? ExerciseFilterOptionsDTO(
            muscleGroups: [
                FilterOptionDTO(value: "chest", label: "Chest", count: 10),
                FilterOptionDTO(value: "back", label: "Back", count: 10)
            ],
            difficulties: [
                FilterOptionDTO(value: "beginner", label: "Beginner", count: 10),
                FilterOptionDTO(value: "intermediate", label: "Intermediate", count: 10)
            ],
            equipment: [
                FilterOptionDTO(value: "barbell", label: "Barbell", count: 10),
                FilterOptionDTO(value: "dumbbell", label: "Dumbbell", count: 10)
            ],
            movementPatterns: [
                FilterOptionDTO(value: "push", label: "Push", count: 10),
                FilterOptionDTO(value: "pull", label: "Pull", count: 10)
            ],
            exerciseTypes: [
                FilterOptionDTO(value: "compound", label: "Compound", count: 10),
                FilterOptionDTO(value: "isolation", label: "Isolation", count: 10)
            ]
        )
    }

    func recordUsage(exerciseId: String) async throws {
        if shouldFail { throw failureError }
    }

    // Test helpers
    func setExercises(_ exercises: [ExerciseDTO]) {
        self.exercises = exercises
    }

    func setShouldFail(_ shouldFail: Bool, error: Error = RepositoryError.networkUnavailable) {
        self.shouldFail = shouldFail
        self.failureError = error
    }
}

// MARK: - Mock Template API Service

actor MockTemplateAPIService: TemplateAPIServiceProtocol {

    var templates: [TemplateDTO] = []
    var shouldFail = false
    var failureError: Error = RepositoryError.networkUnavailable

    func fetchTemplates(cursor: String?, limit: Int) async throws -> (templates: [TemplateDTO], pagination: PaginationInfo) {
        if shouldFail { throw failureError }

        let pagination = PaginationInfo(
            nextCursor: nil,
            hasMore: false
        )
        return (templates, pagination)
    }

    func fetchTemplate(id: String) async throws -> TemplateDTO {
        if shouldFail { throw failureError }

        guard let template = templates.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return template
    }

    func createTemplate(_ request: CreateTemplateRequest) async throws -> TemplateDTO {
        if shouldFail { throw failureError }

        let newTemplate = TemplateDTO(
            id: UUID().uuidString,
            name: request.name,
            description: request.description,
            exercises: [],
            isPublic: request.isPublic,
            isAiGenerated: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        templates.append(newTemplate)
        return newTemplate
    }

    func updateTemplate(id: String, _ request: UpdateTemplateRequest) async throws -> TemplateDTO {
        if shouldFail { throw failureError }

        guard let index = templates.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        var updated = templates[index]
        if let name = request.name {
            updated = TemplateDTO(
                id: updated.id,
                name: name,
                description: request.description ?? updated.description,
                exercises: updated.exercises ?? [],
                isPublic: updated.isPublic,
                isAiGenerated: updated.isAiGenerated,
                createdAt: updated.createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
        }
        templates[index] = updated
        return updated
    }

    func updateTemplateExercises(id: String, _ exercises: [TemplateExerciseInput]) async throws -> TemplateDTO {
        if shouldFail { throw failureError }

        guard let template = templates.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return template
    }

    func cloneTemplate(id: String, newName: String?) async throws -> TemplateDTO {
        if shouldFail { throw failureError }

        guard let original = templates.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        let cloned = TemplateDTO(
            id: UUID().uuidString,
            name: newName ?? "\(original.name) (Copy)",
            description: original.description,
            exercises: original.exercises,
            isPublic: false,
            isAiGenerated: original.isAiGenerated,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        templates.append(cloned)
        return cloned
    }

    func deleteTemplate(id: String) async throws {
        if shouldFail { throw failureError }
        templates.removeAll { $0.id == id }
    }

    // Test helpers
    func setTemplates(_ templates: [TemplateDTO]) {
        self.templates = templates
    }

    func setShouldFail(_ shouldFail: Bool, error: Error = RepositoryError.networkUnavailable) {
        self.shouldFail = shouldFail
        self.failureError = error
    }
}

// MARK: - Mock Program API Service

actor MockProgramAPIService: ProgramAPIServiceProtocol {

    var programs: [ProgramDTO] = []
    var activeProgram: ActiveProgramDTO?
    var shouldFail = false
    var failureError: Error = RepositoryError.networkUnavailable

    func fetchPrograms(cursor: String?, limit: Int) async throws -> (programs: [ProgramDTO], pagination: PaginationInfo) {
        if shouldFail { throw failureError }

        let pagination = PaginationInfo(
            nextCursor: nil,
            hasMore: false
        )
        return (programs, pagination)
    }

    func fetchProgram(id: String) async throws -> ProgramDTO {
        if shouldFail { throw failureError }

        guard let program = programs.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return program
    }

    func fetchActiveProgram() async throws -> ActiveProgramDTO? {
        if shouldFail { throw failureError }
        return activeProgram
    }

    func createProgram(_ request: CreateProgramRequest) async throws -> ProgramDTO {
        if shouldFail { throw failureError }

        let newProgram = ProgramDTO(
            id: UUID().uuidString,
            name: request.name,
            description: request.description,
            daysPerWeek: request.daysPerWeek,
            durationWeeks: request.durationWeeks,
            workouts: [],
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: request.isPublic,
            isAiGenerated: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        programs.append(newProgram)
        return newProgram
    }

    func updateProgram(id: String, _ request: UpdateProgramRequest) async throws -> ProgramDTO {
        if shouldFail { throw failureError }

        guard let program = programs.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return program
    }

    func updateProgramWorkouts(id: String, _ workouts: [ProgramWorkoutInput]) async throws -> ProgramDTO {
        if shouldFail { throw failureError }

        guard let program = programs.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return program
    }

    func deleteProgram(id: String) async throws {
        if shouldFail { throw failureError }
        programs.removeAll { $0.id == id }
    }

    func activateProgram(id: String) async throws -> ProgramDTO {
        if shouldFail { throw failureError }

        guard var program = programs.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        // Create updated program with isActive = true
        program = ProgramDTO(
            id: program.id,
            name: program.name,
            description: program.description,
            daysPerWeek: program.daysPerWeek,
            durationWeeks: program.durationWeeks,
            workouts: program.workouts,
            isActive: true,
            currentDayIndex: program.currentDayIndex,
            timesCompleted: program.timesCompleted,
            isPublic: program.isPublic,
            isAiGenerated: program.isAiGenerated,
            createdAt: program.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        return program
    }

    func deactivateProgram(id: String) async throws -> ProgramDTO {
        if shouldFail { throw failureError }

        guard let program = programs.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return program
    }

    func advanceProgram(id: String) async throws -> ProgramDTO {
        if shouldFail { throw failureError }

        guard let program = programs.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return program
    }

    func resetProgram(id: String) async throws -> ProgramDTO {
        if shouldFail { throw failureError }

        guard let program = programs.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return program
    }

    // Test helpers
    func setPrograms(_ programs: [ProgramDTO]) {
        self.programs = programs
    }

    func setActiveProgram(_ program: ActiveProgramDTO?) {
        self.activeProgram = program
    }

    func setShouldFail(_ shouldFail: Bool, error: Error = RepositoryError.networkUnavailable) {
        self.shouldFail = shouldFail
        self.failureError = error
    }
}

// MARK: - Mock Sync API Service

actor MockSyncAPIService: SyncAPIServiceProtocol {

    var shouldFail = false
    var failureError: Error = RepositoryError.networkUnavailable
    var response: SyncResponseDTO?

    func sync(payload: SyncRequestDTO) async throws -> SyncResponseDTO {
        if shouldFail { throw failureError }

        return response ?? SyncResponseDTO(
            success: true,
            syncedAt: ISO8601DateFormatter().string(from: Date()),
            conflicts: nil,
            serverData: nil,
            stats: SyncStatsDTO(uploaded: 0, downloaded: 0, conflicts: 0)
        )
    }

    func setShouldFail(_ shouldFail: Bool, error: Error = RepositoryError.networkUnavailable) {
        self.shouldFail = shouldFail
        self.failureError = error
    }

    func setResponse(_ response: SyncResponseDTO) {
        self.response = response
    }
}

// MARK: - Test DTO Helpers

extension ExerciseDTO {
    static func sample(
        id: String = "exercise-1",
        name: String = "Bench Press",
        primaryMuscles: [String] = ["chest"],
        equipment: String? = "barbell"
    ) -> ExerciseDTO {
        ExerciseDTO(
            id: id,
            name: name,
            primaryMuscles: primaryMuscles,
            secondaryMuscles: ["triceps", "shoulders"],
            equipment: equipment,
            difficulty: "intermediate",
            movementPattern: "push",
            exerciseType: "compound",
            instructions: "Press the bar",
            videoUrl: "https://example.com/video",
            thumbnailUrl: "https://example.com/thumb",
            popularityScore: 100,
            createdAt: nil,
            updatedAt: nil
        )
    }
}

extension TemplateDTO {
    static func sample(
        id: String = "template-1",
        name: String = "Push Day"
    ) -> TemplateDTO {
        TemplateDTO(
            id: id,
            name: name,
            description: "A push-focused workout",
            exercises: [],
            isPublic: false,
            isAiGenerated: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}

extension ProgramDTO {
    static func sample(
        id: String = "program-1",
        name: String = "PPL Program"
    ) -> ProgramDTO {
        ProgramDTO(
            id: id,
            name: name,
            description: "Push/Pull/Legs split",
            daysPerWeek: 6,
            durationWeeks: 12,
            workouts: [],
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: false,
            isAiGenerated: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}
