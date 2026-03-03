//
//  MockProgramAPIService.swift
//  Nippardation
//
//  Phase 0 Extension: Mock implementation of ProgramAPIServiceProtocol for testing and development
//

import Foundation

/// Mock implementation of ProgramAPIServiceProtocol for testing and development
final class MockProgramAPIService: ProgramAPIServiceProtocol, @unchecked Sendable {

    // MARK: - Test Configuration

    var shouldThrowError = false
    var errorToThrow: RepositoryError = .networkUnavailable
    var fetchDelay: TimeInterval = 0.1

    /// Programs to return
    var programDTOs: [ProgramDTO] = []

    /// Active program response (nil = no active program)
    var activeProgramDTO: ActiveProgramDTO?

    // MARK: - Call Tracking

    private(set) var fetchProgramsCallCount = 0
    private(set) var fetchProgramCallCount = 0
    private(set) var fetchActiveProgramCallCount = 0
    private(set) var createProgramCallCount = 0
    private(set) var updateProgramCallCount = 0
    private(set) var updateProgramWorkoutsCallCount = 0
    private(set) var deleteProgramCallCount = 0
    private(set) var activateProgramCallCount = 0
    private(set) var deactivateProgramCallCount = 0
    private(set) var advanceProgramCallCount = 0
    private(set) var resetProgramCallCount = 0

    private(set) var lastCreateRequest: CreateProgramRequest?
    private(set) var lastUpdateRequest: UpdateProgramRequest?
    private(set) var lastWorkoutInputs: [ProgramWorkoutInput]?

    // MARK: - Initialization

    init() {
        programDTOs = Self.sampleProgramDTOs
        // Set up active program
        if let activeProgram = programDTOs.first(where: { $0.isActive == true }) {
            activeProgramDTO = ActiveProgramDTO(
                program: activeProgram,
                nextWorkout: activeProgram.workouts?.first { $0.dayNumber == (activeProgram.currentDayIndex ?? 0) },
                isCompleted: false
            )
        }
    }

    // MARK: - CRUD Operations

    func fetchPrograms(
        cursor: String?,
        limit: Int
    ) async throws -> (programs: [ProgramDTO], pagination: PaginationInfo) {
        fetchProgramsCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        let startIndex: Int
        if let cursor, let parsed = Int(cursor) {
            startIndex = min(parsed, programDTOs.count)
        } else {
            startIndex = 0
        }
        let endIndex = min(startIndex + limit, programDTOs.count)
        let page = startIndex < programDTOs.count ? Array(programDTOs[startIndex..<endIndex]) : []
        let hasMore = endIndex < programDTOs.count

        return (page, PaginationInfo(nextCursor: hasMore ? String(endIndex) : nil, hasMore: hasMore))
    }

    func fetchProgram(id: String) async throws -> ProgramDTO {
        fetchProgramCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        guard let dto = programDTOs.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        return dto
    }

    func fetchActiveProgram() async throws -> ActiveProgramDTO? {
        fetchActiveProgramCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        return activeProgramDTO
    }

    func createProgram(_ request: CreateProgramRequest) async throws -> ProgramDTO {
        createProgramCallCount += 1
        lastCreateRequest = request

        if shouldThrowError {
            throw errorToThrow
        }

        // Create workouts from inputs
        let workouts = request.workouts.map { input in
            ProgramWorkoutDTO(
                id: UUID().uuidString,
                dayNumber: input.dayNumber,
                dayLabel: input.dayLabel,
                templateId: input.templateId,
                template: nil
            )
        }

        let now = ISO8601DateFormatter().string(from: Date())
        let newDTO = ProgramDTO(
            id: UUID().uuidString,
            name: request.name,
            description: request.description,
            daysPerWeek: request.daysPerWeek,
            durationWeeks: request.durationWeeks,
            workouts: workouts,
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: request.isPublic,
            isAiGenerated: false,
            createdAt: now,
            updatedAt: now
        )

        programDTOs.append(newDTO)
        return newDTO
    }

    func updateProgram(id: String, _ request: UpdateProgramRequest) async throws -> ProgramDTO {
        updateProgramCallCount += 1
        lastUpdateRequest = request

        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = programDTOs.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        let existing = programDTOs[index]
        let now = ISO8601DateFormatter().string(from: Date())
        let updated = ProgramDTO(
            id: existing.id,
            name: request.name ?? existing.name,
            description: request.description ?? existing.description,
            daysPerWeek: request.daysPerWeek ?? existing.daysPerWeek,
            durationWeeks: request.durationWeeks ?? existing.durationWeeks,
            workouts: existing.workouts,
            isActive: existing.isActive,
            currentDayIndex: existing.currentDayIndex,
            timesCompleted: existing.timesCompleted,
            isPublic: existing.isPublic,
            isAiGenerated: existing.isAiGenerated,
            createdAt: existing.createdAt,
            updatedAt: now
        )

        programDTOs[index] = updated
        return updated
    }

    func updateProgramWorkouts(
        id: String,
        _ workouts: [ProgramWorkoutInput]
    ) async throws -> ProgramDTO {
        updateProgramWorkoutsCallCount += 1
        lastWorkoutInputs = workouts

        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = programDTOs.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        let existing = programDTOs[index]
        let workoutDTOs = workouts.map { input in
            ProgramWorkoutDTO(
                id: UUID().uuidString,
                dayNumber: input.dayNumber,
                dayLabel: input.dayLabel,
                templateId: input.templateId,
                template: nil
            )
        }

        let now = ISO8601DateFormatter().string(from: Date())
        let updated = ProgramDTO(
            id: existing.id,
            name: existing.name,
            description: existing.description,
            daysPerWeek: existing.daysPerWeek,
            durationWeeks: existing.durationWeeks,
            workouts: workoutDTOs,
            isActive: existing.isActive,
            currentDayIndex: existing.currentDayIndex,
            timesCompleted: existing.timesCompleted,
            isPublic: existing.isPublic,
            isAiGenerated: existing.isAiGenerated,
            createdAt: existing.createdAt,
            updatedAt: now
        )

        programDTOs[index] = updated
        return updated
    }

    func deleteProgram(id: String) async throws {
        deleteProgramCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        programDTOs.removeAll { $0.id == id }

        // Clear active program if it was deleted
        if activeProgramDTO?.program.id == id {
            activeProgramDTO = nil
        }
    }

    // MARK: - State Management

    func activateProgram(id: String) async throws -> ProgramDTO {
        activateProgramCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = programDTOs.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        let now = ISO8601DateFormatter().string(from: Date())

        // Deactivate all others
        for i in 0..<programDTOs.count {
            if programDTOs[i].isActive == true {
                let existing = programDTOs[i]
                programDTOs[i] = ProgramDTO(
                    id: existing.id,
                    name: existing.name,
                    description: existing.description,
                    daysPerWeek: existing.daysPerWeek,
                    durationWeeks: existing.durationWeeks,
                    workouts: existing.workouts,
                    isActive: false,
                    currentDayIndex: existing.currentDayIndex,
                    timesCompleted: existing.timesCompleted,
                    isPublic: existing.isPublic,
                    isAiGenerated: existing.isAiGenerated,
                    createdAt: existing.createdAt,
                    updatedAt: now
                )
            }
        }

        // Activate this one
        let existing = programDTOs[index]
        let activated = ProgramDTO(
            id: existing.id,
            name: existing.name,
            description: existing.description,
            daysPerWeek: existing.daysPerWeek,
            durationWeeks: existing.durationWeeks,
            workouts: existing.workouts,
            isActive: true,
            currentDayIndex: existing.currentDayIndex,
            timesCompleted: existing.timesCompleted,
            isPublic: existing.isPublic,
            isAiGenerated: existing.isAiGenerated,
            createdAt: existing.createdAt,
            updatedAt: now
        )
        programDTOs[index] = activated

        // Update active program response
        activeProgramDTO = ActiveProgramDTO(
            program: activated,
            nextWorkout: activated.workouts?.first { $0.dayNumber == (activated.currentDayIndex ?? 0) },
            isCompleted: false
        )

        return activated
    }

    func deactivateProgram(id: String) async throws -> ProgramDTO {
        deactivateProgramCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = programDTOs.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        let existing = programDTOs[index]
        let now = ISO8601DateFormatter().string(from: Date())
        let deactivated = ProgramDTO(
            id: existing.id,
            name: existing.name,
            description: existing.description,
            daysPerWeek: existing.daysPerWeek,
            durationWeeks: existing.durationWeeks,
            workouts: existing.workouts,
            isActive: false,
            currentDayIndex: existing.currentDayIndex,
            timesCompleted: existing.timesCompleted,
            isPublic: existing.isPublic,
            isAiGenerated: existing.isAiGenerated,
            createdAt: existing.createdAt,
            updatedAt: now
        )

        programDTOs[index] = deactivated

        // Clear active program if it was deactivated
        if activeProgramDTO?.program.id == id {
            activeProgramDTO = nil
        }

        return deactivated
    }

    func advanceProgram(id: String) async throws -> ProgramDTO {
        advanceProgramCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = programDTOs.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        let existing = programDTOs[index]
        let currentDay = existing.currentDayIndex ?? 0
        // Use workouts.count (matching domain model) with guard against zero
        let workoutCount = max(existing.workouts?.count ?? 0, 1)
        let nextDayIndex = (currentDay + 1) % workoutCount
        let cycleCompleted = nextDayIndex == 0

        let now = ISO8601DateFormatter().string(from: Date())
        let advanced = ProgramDTO(
            id: existing.id,
            name: existing.name,
            description: existing.description,
            daysPerWeek: existing.daysPerWeek,
            durationWeeks: existing.durationWeeks,
            workouts: existing.workouts,
            isActive: existing.isActive,
            currentDayIndex: nextDayIndex,
            timesCompleted: (existing.timesCompleted ?? 0) + (cycleCompleted ? 1 : 0),
            isPublic: existing.isPublic,
            isAiGenerated: existing.isAiGenerated,
            createdAt: existing.createdAt,
            updatedAt: now
        )

        programDTOs[index] = advanced

        // Update active program if this was it
        if activeProgramDTO?.program.id == id {
            activeProgramDTO = ActiveProgramDTO(
                program: advanced,
                nextWorkout: advanced.workouts?.first { $0.dayNumber == nextDayIndex },
                isCompleted: false
            )
        }

        return advanced
    }

    func resetProgram(id: String) async throws -> ProgramDTO {
        resetProgramCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = programDTOs.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        let existing = programDTOs[index]
        let now = ISO8601DateFormatter().string(from: Date())
        let reset = ProgramDTO(
            id: existing.id,
            name: existing.name,
            description: existing.description,
            daysPerWeek: existing.daysPerWeek,
            durationWeeks: existing.durationWeeks,
            workouts: existing.workouts,
            isActive: existing.isActive,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: existing.isPublic,
            isAiGenerated: existing.isAiGenerated,
            createdAt: existing.createdAt,
            updatedAt: now
        )

        programDTOs[index] = reset

        // Update active program if this was it
        if activeProgramDTO?.program.id == id {
            activeProgramDTO = ActiveProgramDTO(
                program: reset,
                nextWorkout: reset.workouts?.first { $0.dayNumber == 0 },
                isCompleted: false
            )
        }

        return reset
    }

    /// Reset all tracking state
    func reset() {
        fetchProgramsCallCount = 0
        fetchProgramCallCount = 0
        fetchActiveProgramCallCount = 0
        createProgramCallCount = 0
        updateProgramCallCount = 0
        updateProgramWorkoutsCallCount = 0
        deleteProgramCallCount = 0
        activateProgramCallCount = 0
        deactivateProgramCallCount = 0
        advanceProgramCallCount = 0
        resetProgramCallCount = 0
        lastCreateRequest = nil
        lastUpdateRequest = nil
        lastWorkoutInputs = nil
        shouldThrowError = false
        programDTOs = Self.sampleProgramDTOs
    }
}

// MARK: - Sample Data

extension MockProgramAPIService {

    static let sampleProgramDTOs: [ProgramDTO] = [
        ProgramDTO(
            id: "prog_001",
            name: "Push Pull Legs",
            description: "Classic 6-day PPL split",
            daysPerWeek: 6,
            durationWeeks: nil,
            workouts: [
                ProgramWorkoutDTO(id: "pw_001", dayNumber: 0, dayLabel: "Push A", templateId: "tmpl_001", template: nil),
                ProgramWorkoutDTO(id: "pw_002", dayNumber: 1, dayLabel: "Pull A", templateId: "tmpl_002", template: nil),
                ProgramWorkoutDTO(id: "pw_003", dayNumber: 2, dayLabel: "Legs A", templateId: "tmpl_003", template: nil),
                ProgramWorkoutDTO(id: "pw_004", dayNumber: 3, dayLabel: "Push B", templateId: "tmpl_001", template: nil),
                ProgramWorkoutDTO(id: "pw_005", dayNumber: 4, dayLabel: "Pull B", templateId: "tmpl_002", template: nil),
                ProgramWorkoutDTO(id: "pw_006", dayNumber: 5, dayLabel: "Legs B", templateId: "tmpl_003", template: nil)
            ],
            isActive: true,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: false,
            isAiGenerated: false,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        ),
        ProgramDTO(
            id: "prog_002",
            name: "Upper Lower",
            description: "4-day upper/lower split",
            daysPerWeek: 4,
            durationWeeks: 8,
            workouts: [
                ProgramWorkoutDTO(id: "pw_007", dayNumber: 0, dayLabel: "Upper A", templateId: "tmpl_001", template: nil),
                ProgramWorkoutDTO(id: "pw_008", dayNumber: 1, dayLabel: "Lower A", templateId: "tmpl_003", template: nil),
                ProgramWorkoutDTO(id: "pw_009", dayNumber: 2, dayLabel: "Upper B", templateId: "tmpl_002", template: nil),
                ProgramWorkoutDTO(id: "pw_010", dayNumber: 3, dayLabel: "Lower B", templateId: "tmpl_003", template: nil)
            ],
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 2,
            isPublic: false,
            isAiGenerated: false,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        )
    ]
}
