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

    /// Templates embedded in a program response never nest the exercise object, so every
    /// program that comes back from the API is hydrated through the same resolver the
    /// template repository uses. Without this an un-activated plan reads "Exercise" on
    /// every row.
    private let resolver: ExerciseLibraryResolver

    // MARK: - Configuration

    private let defaultPageSize = 20

    // MARK: - Initialization

    init(
        apiService: ProgramAPIServiceProtocol,
        coreDataManager: CoreDataManager = .shared,
        exerciseAPIService: (any ExerciseAPIServiceProtocol)? = nil
    ) {
        self.apiService = apiService
        self.coreDataManager = coreDataManager
        self.resolver = ExerciseLibraryResolver(
            coreDataManager: coreDataManager,
            exerciseAPIService: exerciseAPIService
        )
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

            // List endpoints may omit workouts. Merge cached workout data so
            // workout counts remain accurate and cached workouts aren't lost.
            let cached = getCachedPrograms()
            if !cached.isEmpty {
                let cachedByServerId = Dictionary(
                    cached.map { ($0.serverId, $0) },
                    uniquingKeysWith: { first, _ in first }
                )
                allPrograms = allPrograms.map { program in
                    guard program.workouts.isEmpty,
                          let cachedProgram = cachedByServerId[program.serverId],
                          !cachedProgram.workouts.isEmpty else {
                        return program
                    }
                    var merged = program
                    merged.workouts = cachedProgram.workouts
                    return merged
                }
            }

            // Hydrate the embedded templates' exercises in one deduplicated batch, so a
            // movement that repeats across days costs a single request.
            let filled: [Program] = allPrograms.map { fillTemplatesFromCache($0) }
            allPrograms = await resolver.resolve(filled)

            // Cache all programs (preserves existing workouts for list-fetched programs)
            for program in allPrograms {
                try? await coreDataManager.cacheProgram(program)
                await cacheEmbeddedTemplates(of: program)
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
        // Check cache first if not forcing refresh. This is the drill-into-a-plan path, so
        // resolve the exercise library items too: a plan created on another device can be
        // cached here while its movements have never been fetched into the exercise cache,
        // and without this its rows would read "Exercise" forever.
        if !forceRefresh, let cached = getCachedProgram(serverId: serverId) {
            return await resolver.resolve(cached)
        }

        do {
            let dto = try await apiService.fetchProgram(id: serverId)
            let program = await hydrate(ProgramMapper.toDomain(dto))

            // Cache the result
            try? await coreDataManager.cacheProgram(program)
            await cacheEmbeddedTemplates(of: program)

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
        let publicPrograms: [Program] = dtos
            .filter { $0.isPublic ?? false }
            .map { ProgramMapper.toDomain($0) }
        let programs = await resolver.resolve(publicPrograms)

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
        let createdProgram = await hydrate(ProgramMapper.toDomain(dto))

        // Cache the new program
        try? await coreDataManager.cacheProgram(createdProgram)
        await cacheEmbeddedTemplates(of: createdProgram)

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

        let updatedProgram = await hydrate(ProgramMapper.toDomain(dto))

        // Update cache
        try? await coreDataManager.cacheProgram(updatedProgram)
        await cacheEmbeddedTemplates(of: updatedProgram)

        return updatedProgram
    }

    func deleteProgram(serverId: String) async throws {
        try await apiService.deleteProgram(id: serverId)

        // Remove from cache
        try? await coreDataManager.deleteCachedProgram(serverId: serverId)
    }

    func deleteProgram(serverId: String, deleteTemplates: Bool, keepTemplateIds: [String], programTemplateIds: [String]) async throws {
        _ = try await apiService.deleteProgram(id: serverId, deleteTemplates: deleteTemplates, keepTemplateIds: keepTemplateIds)

        // Remove program from cache
        try? await coreDataManager.deleteCachedProgram(serverId: serverId)

        // Remove templates the server deleted (those in this program but NOT in keepTemplateIds)
        if deleteTemplates {
            let keepSet = Set(keepTemplateIds)
            for templateId in Set(programTemplateIds) where !keepSet.contains(templateId) {
                try? await coreDataManager.deleteCachedTemplate(serverId: templateId)
            }
        }
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

            let program = await hydrate(ProgramMapper.toDomain(dto.program))

            // Cache the active program
            try? await coreDataManager.cacheProgram(program)
            await cacheEmbeddedTemplates(of: program)

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
        let program = await hydrate(ProgramMapper.toDomain(dto))

        // Update local cache
        try? await coreDataManager.setActiveProgram(serverId: serverId)
        try? await coreDataManager.cacheProgram(program)
        await cacheEmbeddedTemplates(of: program)

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
        // Progress updates are local-only since UpdateProgramRequest doesn't support progress fields.
        // Progress will sync to server via advanceProgram() API calls when user advances through workouts.
        try await coreDataManager.updateProgramProgress(
            serverId: program.serverId,
            currentDayIndex: program.currentDayIndex,
            timesCompleted: program.timesCompleted
        )

        // Return the program with updated progress values
        return program
    }

    func advanceToNextWorkout(serverId: String) async throws -> Program {
        let dto = try await apiService.advanceProgram(id: serverId)
        let program = await hydrate(ProgramMapper.toDomain(dto))

        // Update local cache
        try? await coreDataManager.cacheProgram(program)
        await cacheEmbeddedTemplates(of: program)

        return program
    }

    func resetProgram(serverId: String) async throws -> Program {
        let dto = try await apiService.resetProgram(id: serverId)
        let program = await hydrate(ProgramMapper.toDomain(dto))

        // Update local cache
        try? await coreDataManager.cacheProgram(program)
        await cacheEmbeddedTemplates(of: program)

        return program
    }

    // MARK: - Embedded Templates

    /// Everything a program coming off the API needs before anyone reads a name off it:
    /// fill in workouts the response summarised away, then resolve the exercise library
    /// items its templates arrived without. Never throws — an offline read degrades to
    /// whatever the caches hold.
    private func hydrate(_ program: Program) async -> Program {
        await resolver.resolve(fillTemplatesFromCache(program))
    }

    /// Program responses embed each workout's template as a summary, often with no
    /// exercises at all. Fill those from the template cache so a plan the user has not
    /// activated still shows its real workouts (and therefore its real movement names)
    /// instead of empty rows.
    private func fillTemplatesFromCache(_ program: Program) -> Program {
        var updated = program
        updated.workouts = program.workouts.map { workout in
            let embedded = workout.template
            guard embedded == nil || embedded?.exercises.isEmpty == true else { return workout }

            let templateId = embedded.map { $0.serverId.isEmpty ? workout.templateServerId : $0.serverId }
                ?? workout.templateServerId
            guard !templateId.isEmpty,
                  let cached = coreDataManager.fetchCachedTemplate(serverId: templateId) else {
                return workout
            }

            var template = coreDataManager.toDomain(cached)
            guard !template.exercises.isEmpty else { return workout }
            // The response is newer than the cache for the workout's own fields.
            if let embedded {
                template.name = embedded.name
                template.description = embedded.description
            }

            var updatedWorkout = workout
            updatedWorkout.template = template
            return updatedWorkout
        }
        return updated
    }

    /// Caches the workouts a program response carried.
    ///
    /// `cacheProgram` only stores the rotation, so without this the workouts a plan response
    /// embedded would never reach `CDTemplate`, and an offline read of a plan the user has
    /// not activated would have no exercises — and therefore no names — to show.
    ///
    /// Templates the cache already holds unchanged are skipped: most program responses
    /// summarise their templates away and `fillTemplatesFromCache` puts the cached copy
    /// back, and rewriting that copy on every plan read is pure churn. Exercise library
    /// items are deliberately not re-cached here — the resolver already caches what it
    /// fetched, and rewriting cache-resolved items would refresh their `lastFetchedAt`
    /// without a network round trip, so they would never look stale again.
    private func cacheEmbeddedTemplates(of program: Program) async {
        for workout in program.workouts {
            guard let template = workout.template,
                  !template.serverId.isEmpty,
                  !template.exercises.isEmpty,
                  templateCacheNeedsUpdate(template) else { continue }
            try? await coreDataManager.cacheTemplate(template)
        }
    }

    /// True when the cached copy of this template differs from the one that just arrived.
    private func templateCacheNeedsUpdate(_ template: Template) -> Bool {
        guard let cached = coreDataManager.fetchCachedTemplate(serverId: template.serverId) else {
            return true
        }
        if cached.name != template.name { return true }

        let cachedExercises = cached.exercisesArray
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { exercise -> String in
                "\(exercise.exerciseServerId ?? "")|\(exercise.warmupSets)|\(exercise.workingSets)|\(exercise.targetReps ?? "")|\(exercise.restSeconds)"
            }
        let incomingExercises = template.exercises
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { exercise -> String in
                "\(exercise.exerciseServerId)|\(exercise.warmupSets ?? 0)|\(exercise.workingSets)|\(exercise.targetReps ?? "")|\(exercise.restSeconds ?? 0)"
            }
        return cachedExercises != incomingExercises
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
