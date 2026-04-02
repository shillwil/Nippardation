//
//  MockProgramRepository.swift
//  Nippardation
//
//  Phase 0: Mock implementation of ProgramRepositoryProtocol for testing and previews
//

import Foundation

/// Mock implementation of ProgramRepositoryProtocol
/// Provides sample data for testing and SwiftUI previews
@MainActor
final class MockProgramRepository: ProgramRepositoryProtocol {

    // MARK: - Mock Data Storage

    private var programs: [Program] = MockProgramRepository.samplePrograms
    private var pendingPrograms: Set<String> = []
    private var shouldFail = false
    private var delay: TimeInterval = 0

    // MARK: - Configuration

    func setFailure(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }

    // MARK: - ProgramRepositoryProtocol

    func fetchPrograms(forceRefresh: Bool) async throws -> [Program] {
        try await simulateNetworkCall()
        return programs
    }

    func fetchProgram(serverId: String, forceRefresh: Bool) async throws -> Program {
        try await simulateNetworkCall()
        guard let program = programs.first(where: { $0.serverId == serverId }) else {
            throw RepositoryError.notFound
        }
        return program
    }

    func fetchPublicPrograms(page: Int, category: String?) async throws -> PaginatedResult<Program> {
        try await simulateNetworkCall()
        let publicPrograms = programs.filter { $0.isPublic }
        return PaginatedResult(
            items: publicPrograms,
            page: 1,
            totalPages: 1,
            totalItems: publicPrograms.count
        )
    }

    func createProgram(_ program: Program) async throws -> Program {
        try await simulateNetworkCall()
        let newProgram = Program(
            id: program.id,
            serverId: "prog_\(UUID().uuidString.prefix(8))",
            name: program.name,
            description: program.description,
            daysPerWeek: program.daysPerWeek,
            durationWeeks: program.durationWeeks,
            workouts: program.workouts,
            isActive: program.isActive,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: program.isPublic,
            isAiGenerated: program.isAiGenerated,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: Date()
        )
        programs.append(newProgram)
        return newProgram
    }

    func updateProgram(_ program: Program) async throws -> Program {
        try await simulateNetworkCall()
        guard let index = programs.firstIndex(where: { $0.serverId == program.serverId }) else {
            throw RepositoryError.notFound
        }
        programs[index] = program
        return program
    }

    func deleteProgram(serverId: String) async throws {
        try await simulateNetworkCall()
        programs.removeAll { $0.serverId == serverId }
    }

    func deleteProgram(serverId: String, deleteTemplates: Bool, keepTemplateIds: [String], programTemplateIds: [String]) async throws {
        try await simulateNetworkCall()
        programs.removeAll { $0.serverId == serverId }
    }

    func duplicateProgram(serverId: String) async throws -> Program {
        try await simulateNetworkCall()
        guard let original = programs.first(where: { $0.serverId == serverId }) else {
            throw RepositoryError.notFound
        }
        let duplicate = Program(
            id: UUID(),
            serverId: "prog_\(UUID().uuidString.prefix(8))",
            name: "\(original.name) (Copy)",
            description: original.description,
            daysPerWeek: original.daysPerWeek,
            durationWeeks: original.durationWeeks,
            workouts: original.workouts,
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: Date()
        )
        programs.append(duplicate)
        return duplicate
    }

    func getActiveProgram() async throws -> Program? {
        programs.first { $0.isActive }
    }

    func setActiveProgram(serverId: String) async throws -> Program {
        try await simulateNetworkCall()

        // Check existence BEFORE modifying state to avoid corrupting state on error
        guard programs.contains(where: { $0.serverId == serverId }) else {
            throw RepositoryError.notFound
        }

        // Deactivate all others and activate target
        for i in programs.indices {
            programs[i] = Program(
                id: programs[i].id,
                serverId: programs[i].serverId,
                name: programs[i].name,
                description: programs[i].description,
                daysPerWeek: programs[i].daysPerWeek,
                durationWeeks: programs[i].durationWeeks,
                workouts: programs[i].workouts,
                isActive: programs[i].serverId == serverId,
                currentDayIndex: programs[i].currentDayIndex,
                timesCompleted: programs[i].timesCompleted,
                isPublic: programs[i].isPublic,
                isAiGenerated: programs[i].isAiGenerated,
                createdAt: programs[i].createdAt,
                updatedAt: Date(),
                lastFetchedAt: programs[i].lastFetchedAt
            )
        }

        // Safe to force unwrap since we already checked existence
        return programs.first { $0.serverId == serverId }!
    }

    func deactivateProgram() async throws {
        try await simulateNetworkCall()
        for i in programs.indices where programs[i].isActive {
            programs[i] = Program(
                id: programs[i].id,
                serverId: programs[i].serverId,
                name: programs[i].name,
                description: programs[i].description,
                daysPerWeek: programs[i].daysPerWeek,
                durationWeeks: programs[i].durationWeeks,
                workouts: programs[i].workouts,
                isActive: false,
                currentDayIndex: programs[i].currentDayIndex,
                timesCompleted: programs[i].timesCompleted,
                isPublic: programs[i].isPublic,
                isAiGenerated: programs[i].isAiGenerated,
                createdAt: programs[i].createdAt,
                updatedAt: Date(),
                lastFetchedAt: programs[i].lastFetchedAt
            )
        }
    }

    func updateProgramProgress(_ program: Program) async throws -> Program {
        try await updateProgram(program)
    }

    func advanceToNextWorkout(serverId: String) async throws -> Program {
        try await simulateNetworkCall()
        guard let index = programs.firstIndex(where: { $0.serverId == serverId }) else {
            throw RepositoryError.notFound
        }
        var program = programs[index]
        program.advanceToNextWorkout()
        programs[index] = program
        return program
    }

    func getCachedPrograms() -> [Program] {
        programs
    }

    func getCachedProgram(serverId: String) -> Program? {
        programs.first { $0.serverId == serverId }
    }

    func cacheProgram(_ program: Program) async throws {
        if !programs.contains(where: { $0.id == program.id }) {
            programs.append(program)
        }
    }

    func clearCache() async throws {
        programs = MockProgramRepository.samplePrograms
    }

    func getPendingPrograms() -> [Program] {
        programs.filter { pendingPrograms.contains($0.serverId) }
    }

    func markProgramSynced(serverId: String) async throws {
        pendingPrograms.remove(serverId)
    }

    // MARK: - Helpers

    private func simulateNetworkCall() async throws {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if shouldFail {
            throw RepositoryError.networkUnavailable
        }
    }
}

// MARK: - Sample Data

extension MockProgramRepository {

    static var samplePrograms: [Program] {
        let templates = MockTemplateRepository.sampleTemplates
        let pushTemplate = templates.first { $0.name == "Push Day" }
        let pullTemplate = templates.first { $0.name == "Pull Day" }
        let legTemplate = templates.first { $0.name == "Leg Day" }

        return [
            Program(
                id: UUID(),
                serverId: "prog_001",
                name: "Push Pull Legs",
                description: "Classic 3-day split for hypertrophy",
                daysPerWeek: 6,
                durationWeeks: nil,
                workouts: [
                    ProgramWorkout(
                        id: UUID(),
                        serverId: "pw_001",
                        dayNumber: 0,
                        dayLabel: "Push",
                        templateServerId: pushTemplate?.serverId ?? "",
                        template: pushTemplate
                    ),
                    ProgramWorkout(
                        id: UUID(),
                        serverId: "pw_002",
                        dayNumber: 1,
                        dayLabel: "Pull",
                        templateServerId: pullTemplate?.serverId ?? "",
                        template: pullTemplate
                    ),
                    ProgramWorkout(
                        id: UUID(),
                        serverId: "pw_003",
                        dayNumber: 2,
                        dayLabel: "Legs",
                        templateServerId: legTemplate?.serverId ?? "",
                        template: legTemplate
                    ),
                    ProgramWorkout(
                        id: UUID(),
                        serverId: "pw_004",
                        dayNumber: 3,
                        dayLabel: "Push",
                        templateServerId: pushTemplate?.serverId ?? "",
                        template: pushTemplate
                    ),
                    ProgramWorkout(
                        id: UUID(),
                        serverId: "pw_005",
                        dayNumber: 4,
                        dayLabel: "Pull",
                        templateServerId: pullTemplate?.serverId ?? "",
                        template: pullTemplate
                    ),
                    ProgramWorkout(
                        id: UUID(),
                        serverId: "pw_006",
                        dayNumber: 5,
                        dayLabel: "Legs",
                        templateServerId: legTemplate?.serverId ?? "",
                        template: legTemplate
                    )
                ],
                isActive: true,
                currentDayIndex: 1,
                timesCompleted: 2,
                isPublic: false,
                isAiGenerated: false,
                createdAt: Date().addingTimeInterval(-86400 * 60),
                updatedAt: Date(),
                lastFetchedAt: Date()
            ),
            Program(
                id: UUID(),
                serverId: "prog_002",
                name: "Upper Lower",
                description: "4-day upper/lower split",
                daysPerWeek: 4,
                durationWeeks: 8,
                workouts: [
                    ProgramWorkout(
                        id: UUID(),
                        serverId: "pw_007",
                        dayNumber: 0,
                        dayLabel: "Upper A",
                        templateServerId: pushTemplate?.serverId ?? "",
                        template: pushTemplate
                    ),
                    ProgramWorkout(
                        id: UUID(),
                        serverId: "pw_008",
                        dayNumber: 1,
                        dayLabel: "Lower A",
                        templateServerId: legTemplate?.serverId ?? "",
                        template: legTemplate
                    ),
                    ProgramWorkout(
                        id: UUID(),
                        serverId: "pw_009",
                        dayNumber: 2,
                        dayLabel: "Upper B",
                        templateServerId: pullTemplate?.serverId ?? "",
                        template: pullTemplate
                    ),
                    ProgramWorkout(
                        id: UUID(),
                        serverId: "pw_010",
                        dayNumber: 3,
                        dayLabel: "Lower B",
                        templateServerId: legTemplate?.serverId ?? "",
                        template: legTemplate
                    )
                ],
                isActive: false,
                currentDayIndex: 0,
                timesCompleted: 0,
                isPublic: false,
                isAiGenerated: false,
                createdAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date().addingTimeInterval(-86400 * 7),
                lastFetchedAt: Date()
            )
        ]
    }
}
