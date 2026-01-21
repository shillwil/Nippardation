//
//  ProgramRepository.swift
//  Nippardation
//
//  Concrete implementation of ProgramRepositoryProtocol
//  Combines API calls with local Core Data caching
//

import Foundation

/// Concrete implementation of ProgramRepositoryProtocol
/// Combines API calls with local Core Data caching
@MainActor
final class ProgramRepository: ProgramRepositoryProtocol {

    // MARK: - Dependencies

    private let apiService: ProgramAPIServiceProtocol
    private let coreDataManager: CoreDataManager

    // MARK: - Configuration

    private let defaultPageSize = 20

    // MARK: - Initialization

    init(
        apiService: ProgramAPIServiceProtocol,
        coreDataManager: CoreDataManager = .shared
    ) {
        self.apiService = apiService
        self.coreDataManager = coreDataManager
    }

    // MARK: - Fetch Operations

    func fetchPrograms(forceRefresh: Bool) async throws -> [Program] {
        // Check cache first if not forcing refresh
        if !forceRefresh {
            let cached = getCachedPrograms()
            if !cached.isEmpty {
                return cached
            }
        }

        do {
            // Fetch all programs (may need multiple pages)
            var allPrograms: [Program] = []
            var cursor: String? = nil
            var hasMore = true

            while hasMore {
                let (dtos, pagination) = try await apiService.fetchPrograms(
                    cursor: cursor,
                    limit: defaultPageSize
                )

                let programs = dtos.map { ProgramMapper.toDomain($0) }
                allPrograms.append(contentsOf: programs)

                cursor = pagination.nextCursor
                hasMore = pagination.hasMore
            }

            // Cache all programs
            for program in allPrograms {
                try? await coreDataManager.cacheProgram(program)
            }

            return allPrograms
        } catch {
            // Fallback to cache
            let cached = getCachedPrograms()
            if !cached.isEmpty {
                return cached
            }
            throw error
        }
    }

    func fetchProgram(serverId: String, forceRefresh: Bool) async throws -> Program {
        // Check cache first if not forcing refresh
        if !forceRefresh, let cached = getCachedProgram(serverId: serverId) {
            return cached
        }

        do {
            let dto = try await apiService.fetchProgram(id: serverId)
            let program = ProgramMapper.toDomain(dto)

            // Cache the result
            try? await coreDataManager.cacheProgram(program)

            return program
        } catch {
            // Try cache as fallback
            if let cached = getCachedProgram(serverId: serverId) {
                return cached
            }
            throw RepositoryError.notFound
        }
    }

    func fetchPublicPrograms(page: Int, category: String?) async throws -> PaginatedResult<Program> {
        // Public programs are fetched from API
        let cursor = page > 1 ? String((page - 1) * defaultPageSize) : nil

        let (dtos, pagination) = try await apiService.fetchPrograms(
            cursor: cursor,
            limit: defaultPageSize
        )

        // Filter by isPublic
        let programs = dtos
            .filter { $0.isPublic ?? false }
            .map { ProgramMapper.toDomain($0) }

        let totalPages = pagination.hasMore ? (page + 1) : page
        let totalItems = pagination.hasMore ? (page * defaultPageSize + 1) : programs.count

        return PaginatedResult(
            items: programs,
            page: page,
            totalPages: totalPages,
            totalItems: totalItems
        )
    }

    // MARK: - CRUD Operations

    func createProgram(_ program: Program) async throws -> Program {
        // Build request
        let workoutInputs = program.workouts.map { workout in
            ProgramWorkoutInput(
                dayNumber: workout.dayNumber,
                dayLabel: workout.dayLabel,
                templateId: workout.templateServerId
            )
        }

        let request = CreateProgramRequest(
            name: program.name,
            description: program.description,
            daysPerWeek: program.daysPerWeek,
            durationWeeks: program.durationWeeks,
            workouts: workoutInputs,
            isPublic: program.isPublic
        )

        let dto = try await apiService.createProgram(request)
        let createdProgram = ProgramMapper.toDomain(dto)

        // Cache the new program
        try? await coreDataManager.cacheProgram(createdProgram)

        return createdProgram
    }

    func updateProgram(_ program: Program) async throws -> Program {
        let request = UpdateProgramRequest(
            name: program.name,
            description: program.description,
            daysPerWeek: program.daysPerWeek,
            durationWeeks: program.durationWeeks
        )

        var dto = try await apiService.updateProgram(id: program.serverId, request)

        // Also update workouts if they changed
        let workoutInputs = program.workouts.map { workout in
            ProgramWorkoutInput(
                dayNumber: workout.dayNumber,
                dayLabel: workout.dayLabel,
                templateId: workout.templateServerId
            )
        }

        dto = try await apiService.updateProgramWorkouts(
            id: program.serverId,
            workoutInputs
        )

        let updatedProgram = ProgramMapper.toDomain(dto)

        // Update cache
        try? await coreDataManager.cacheProgram(updatedProgram)

        return updatedProgram
    }

    func deleteProgram(serverId: String) async throws {
        try await apiService.deleteProgram(id: serverId)

        // Remove from cache
        try? await coreDataManager.deleteCachedProgram(serverId: serverId)
    }

    func duplicateProgram(serverId: String) async throws -> Program {
        // Fetch original program
        let original = try await fetchProgram(serverId: serverId, forceRefresh: true)

        // Create a copy with new name
        var copy = original
        copy = Program(
            id: UUID(),
            serverId: "",
            name: "\(original.name) (Copy)",
            description: original.description,
            daysPerWeek: original.daysPerWeek,
            durationWeeks: original.durationWeeks,
            workouts: original.workouts,
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: false,
            isAiGenerated: original.isAiGenerated,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )

        // Create via API
        return try await createProgram(copy)
    }

    // MARK: - Active Program Management

    func getActiveProgram() async throws -> Program? {
        // Try API first
        do {
            guard let dto = try await apiService.fetchActiveProgram() else {
                return nil
            }

            let program = ProgramMapper.toDomain(dto.program)

            // Cache the active program
            try? await coreDataManager.cacheProgram(program)

            return program
        } catch {
            // Fallback to cached active program
            if let cached = coreDataManager.fetchCachedActiveProgram() {
                return coreDataManager.toDomain(cached)
            }
            throw error
        }
    }

    func setActiveProgram(serverId: String) async throws -> Program {
        let dto = try await apiService.activateProgram(id: serverId)
        let program = ProgramMapper.toDomain(dto)

        // Update local cache
        try? await coreDataManager.setActiveProgram(serverId: serverId)
        try? await coreDataManager.cacheProgram(program)

        return program
    }

    func deactivateProgram() async throws {
        // Get current active program
        if let activeProgram = coreDataManager.fetchCachedActiveProgram(),
           let serverId = activeProgram.serverId {
            _ = try await apiService.deactivateProgram(id: serverId)

            // Update local cache
            try? await coreDataManager.deactivateProgram(serverId: serverId)
        }
    }

    func updateProgramProgress(_ program: Program) async throws -> Program {
        // Update via API through advance or regular update
        let request = UpdateProgramRequest(
            name: nil,
            description: nil,
            daysPerWeek: nil,
            durationWeeks: nil
        )

        let dto = try await apiService.updateProgram(id: program.serverId, request)
        let updatedProgram = ProgramMapper.toDomain(dto)

        // Update local cache
        try? await coreDataManager.updateProgramProgress(
            serverId: program.serverId,
            currentDayIndex: program.currentDayIndex,
            timesCompleted: program.timesCompleted
        )

        return updatedProgram
    }

    func advanceToNextWorkout(serverId: String) async throws -> Program {
        let dto = try await apiService.advanceProgram(id: serverId)
        let program = ProgramMapper.toDomain(dto)

        // Update local cache
        try? await coreDataManager.cacheProgram(program)

        return program
    }

    // MARK: - Cache Operations

    func getCachedPrograms() -> [Program] {
        let cached = coreDataManager.fetchCachedPrograms()
        return cached.map { coreDataManager.toDomain($0) }
    }

    func getCachedProgram(serverId: String) -> Program? {
        guard let cached = coreDataManager.fetchCachedProgram(serverId: serverId) else {
            return nil
        }
        return coreDataManager.toDomain(cached)
    }

    func cacheProgram(_ program: Program) async throws {
        try await coreDataManager.cacheProgram(program)
    }

    func clearCache() async throws {
        try await coreDataManager.clearProgramCache()
    }

    // MARK: - Offline Support

    func getPendingPrograms() -> [Program] {
        let pending = coreDataManager.fetchPendingPrograms()
        return pending.map { coreDataManager.toDomain($0) }
    }

    func markProgramSynced(serverId: String) async throws {
        try await coreDataManager.markProgramSynced(serverId: serverId)
    }
}
