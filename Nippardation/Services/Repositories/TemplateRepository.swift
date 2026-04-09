//
//  TemplateRepository.swift
//  Nippardation
//
//  Concrete implementation of TemplateRepositoryProtocol
//  Combines API calls with local Core Data caching
//

import Foundation

/// Concrete implementation of TemplateRepositoryProtocol
/// Combines API calls with local Core Data caching
@MainActor
final class TemplateRepository: TemplateRepositoryProtocol {

    // MARK: - Dependencies

    private let apiService: TemplateAPIServiceProtocol
    private let coreDataManager: CoreDataManager
    private let exerciseAPIService: (any ExerciseAPIServiceProtocol)?

    // MARK: - Configuration

    private let defaultPageSize = 20

    // MARK: - Initialization

    init(
        apiService: TemplateAPIServiceProtocol,
        coreDataManager: CoreDataManager = .shared,
        exerciseAPIService: (any ExerciseAPIServiceProtocol)? = nil
    ) {
        self.apiService = apiService
        self.coreDataManager = coreDataManager
        self.exerciseAPIService = exerciseAPIService
    }

    // MARK: - Fetch Operations

    func fetchTemplates(forceRefresh: Bool) async throws -> [Template] {
        // Check cache first if not forcing refresh
        if !forceRefresh {
            let cached = getCachedTemplates()
            if !cached.isEmpty {
                return cached
            }
        }

        do {
            // Fetch all templates (may need multiple pages)
            var allTemplates: [Template] = []
            var cursor: String? = nil
            var hasMore = true

            while hasMore {
                let (dtos, pagination) = try await apiService.fetchTemplates(
                    cursor: cursor,
                    limit: defaultPageSize
                )

                let templates = dtos.map { TemplateMapper.toDomain($0) }
                allTemplates.append(contentsOf: templates)

                cursor = pagination.nextCursor
                hasMore = pagination.hasMore
            }

            // List endpoints may omit exercises. Merge cached exercise data so
            // exercise counts remain accurate and cached exercises aren't lost.
            let cached = getCachedTemplates()
            if !cached.isEmpty {
                let cachedByServerId = Dictionary(
                    cached.map { ($0.serverId, $0) },
                    uniquingKeysWith: { first, _ in first }
                )
                allTemplates = allTemplates.map { template in
                    guard template.exercises.isEmpty,
                          let cachedTemplate = cachedByServerId[template.serverId] else {
                        return template
                    }
                    var merged = template
                    if !cachedTemplate.exercises.isEmpty {
                        merged.exercises = cachedTemplate.exercises
                    } else if merged._knownExerciseCount == nil {
                        merged._knownExerciseCount = cachedTemplate._knownExerciseCount
                    }
                    return merged
                }
            }

            // Cache all templates (preserves existing exercises for list-fetched templates)
            try? await coreDataManager.cacheTemplates(allTemplates)

            return allTemplates
        } catch {
            // Fallback to cache
            let cached = getCachedTemplates()
            if !cached.isEmpty {
                return cached
            }
            throw error
        }
    }

    func fetchTemplate(serverId: String, forceRefresh: Bool) async throws -> Template {
        // Check cache first if not forcing refresh
        if !forceRefresh, let cached = getCachedTemplate(serverId: serverId) {
            let hasExercises = !cached.exercises.isEmpty
            let allResolved = cached.exercises.allSatisfy { $0.exerciseLibraryItem != nil }

            // Cache is fully resolved - use it
            if hasExercises && allResolved {
                return cached
            }

            // Exercises present but some unresolved - try resolving from exercise cache
            if hasExercises && !allResolved {
                var resolved = cached
                resolved.exercises = resolveExerciseLibraryItems(resolved.exercises)
                if resolved.exercises.allSatisfy({ $0.exerciseLibraryItem != nil }) {
                    return resolved
                }
            }

            // No exercises or still unresolved - fall through to API fetch
        }

        do {
            let dto = try await apiService.fetchTemplate(id: serverId)
            var template = TemplateMapper.toDomain(dto)

            // Cache exercise library items from the API response so future cache
            // loads can resolve them via fetchCachedExercise(serverId:)
            let libraryItems = template.exercises.compactMap { $0.exerciseLibraryItem }
            if !libraryItems.isEmpty {
                try? await coreDataManager.cacheExercises(libraryItems)
            }

            // Resolve any exercises still missing their library item from cache
            template.exercises = resolveExerciseLibraryItems(template.exercises)

            // For any still missing, fetch individually from exercise API
            template.exercises = await fetchMissingExerciseLibraryItems(template.exercises)

            // Cache the result
            try? await coreDataManager.cacheTemplate(template)

            return template
        } catch {
            // Try cache as fallback
            if let cached = getCachedTemplate(serverId: serverId) {
                return cached
            }
            throw RepositoryError.notFound
        }
    }

    func fetchPublicTemplates(page: Int, category: String?) async throws -> PaginatedResult<Template> {
        // Public templates are not cached locally - always fetch from API
        let cursor = page > 1 ? String((page - 1) * defaultPageSize) : nil

        let (dtos, pagination) = try await apiService.fetchTemplates(
            cursor: cursor,
            limit: defaultPageSize
        )

        // Filter by isPublic (API might not have category filter)
        let templates = dtos
            .filter { $0.isPublic ?? false }
            .map { TemplateMapper.toDomain($0) }

        let totalPages = pagination.hasMore ? (page + 1) : page
        let totalItems = pagination.hasMore ? (page * defaultPageSize + 1) : templates.count

        return PaginatedResult(
            items: templates,
            page: page,
            totalPages: totalPages,
            totalItems: totalItems
        )
    }

    // MARK: - CRUD Operations

    func createTemplate(_ template: Template) async throws -> Template {
        // Build request
        let exerciseInputs = template.exercises.map { exercise in
            TemplateExerciseInput(
                exerciseId: exercise.exerciseServerId,
                orderIndex: exercise.orderIndex,
                warmupSets: exercise.warmupSets,
                workingSets: exercise.workingSets,
                targetReps: exercise.targetReps,
                restSeconds: exercise.restSeconds,
                notes: exercise.notes
            )
        }

        let request = CreateTemplateRequest(
            name: template.name,
            description: template.description,
            exercises: exerciseInputs,
            isPublic: template.isPublic
        )

        let dto = try await apiService.createTemplate(request)
        var createdTemplate = TemplateMapper.toDomain(dto)

        // Cache exercise library items and resolve missing ones
        let libraryItems = createdTemplate.exercises.compactMap { $0.exerciseLibraryItem }
        if !libraryItems.isEmpty {
            try? await coreDataManager.cacheExercises(libraryItems)
        }
        createdTemplate.exercises = resolveExerciseLibraryItems(createdTemplate.exercises)

        // Cache the new template
        try? await coreDataManager.cacheTemplate(createdTemplate)

        return createdTemplate
    }

    func updateTemplate(_ template: Template) async throws -> Template {
        let request = UpdateTemplateRequest(
            name: template.name,
            description: template.description
        )

        let dto = try await apiService.updateTemplate(id: template.serverId, request)

        // Also update exercises if they changed
        let exerciseInputs = template.exercises.map { exercise in
            TemplateExerciseInput(
                exerciseId: exercise.exerciseServerId,
                orderIndex: exercise.orderIndex,
                warmupSets: exercise.warmupSets,
                workingSets: exercise.workingSets,
                targetReps: exercise.targetReps,
                restSeconds: exercise.restSeconds,
                notes: exercise.notes
            )
        }

        let updatedDto = try await apiService.updateTemplateExercises(
            id: template.serverId,
            exerciseInputs
        )

        var updatedTemplate = TemplateMapper.toDomain(updatedDto)

        // Cache exercise library items and resolve missing ones
        let libraryItems = updatedTemplate.exercises.compactMap { $0.exerciseLibraryItem }
        if !libraryItems.isEmpty {
            try? await coreDataManager.cacheExercises(libraryItems)
        }
        updatedTemplate.exercises = resolveExerciseLibraryItems(updatedTemplate.exercises)

        // Update cache
        try? await coreDataManager.cacheTemplate(updatedTemplate)

        return updatedTemplate
    }

    func deleteTemplate(serverId: String) async throws {
        try await apiService.deleteTemplate(id: serverId)

        // Remove from cache
        try? await coreDataManager.deleteCachedTemplate(serverId: serverId)
    }

    func duplicateTemplate(serverId: String) async throws -> Template {
        let dto = try await apiService.cloneTemplate(id: serverId, newName: nil)
        var template = TemplateMapper.toDomain(dto)

        // Cache exercise library items and resolve missing ones
        let libraryItems = template.exercises.compactMap { $0.exerciseLibraryItem }
        if !libraryItems.isEmpty {
            try? await coreDataManager.cacheExercises(libraryItems)
        }
        template.exercises = resolveExerciseLibraryItems(template.exercises)

        // Cache the new template
        try? await coreDataManager.cacheTemplate(template)

        return template
    }

    // MARK: - Cache Operations

    func getCachedTemplates() -> [Template] {
        let cached = coreDataManager.fetchCachedTemplates()
        return cached.map { template in
            var domain = coreDataManager.toDomain(template)
            domain.exercises = resolveExerciseLibraryItems(domain.exercises)
            return domain
        }
    }

    func getCachedTemplate(serverId: String) -> Template? {
        guard let cached = coreDataManager.fetchCachedTemplate(serverId: serverId) else {
            return nil
        }
        var domain = coreDataManager.toDomain(cached)
        domain.exercises = resolveExerciseLibraryItems(domain.exercises)
        return domain
    }

    func cacheTemplate(_ template: Template) async throws {
        try await coreDataManager.cacheTemplate(template)
    }

    func clearCache() async throws {
        try await coreDataManager.clearTemplateCache()
    }

    // MARK: - Offline Support

    func getPendingTemplates() -> [Template] {
        let pending = coreDataManager.fetchPendingTemplates()
        return pending.map { coreDataManager.toDomain($0) }
    }

    func markTemplateSynced(serverId: String) async throws {
        try await coreDataManager.markTemplateSynced(serverId: serverId)
    }

    // MARK: - Exercise Library Item Resolution

    /// Resolves missing exerciseLibraryItem on template exercises from the local exercise cache.
    private func resolveExerciseLibraryItems(_ exercises: [TemplateExercise]) -> [TemplateExercise] {
        exercises.map { exercise in
            guard exercise.exerciseLibraryItem == nil else { return exercise }
            guard let cdExercise = coreDataManager.fetchCachedExercise(serverId: exercise.exerciseServerId) else {
                return exercise
            }
            var resolved = exercise
            resolved.exerciseLibraryItem = coreDataManager.toDomain(cdExercise)
            return resolved
        }
    }

    /// Fetches exercise library items individually from the API for any exercises still missing them.
    private func fetchMissingExerciseLibraryItems(_ exercises: [TemplateExercise]) async -> [TemplateExercise] {
        guard let exerciseAPI = exerciseAPIService else { return exercises }

        var result = exercises
        var fetchedItems: [ExerciseLibraryItem] = []

        for i in result.indices {
            guard result[i].exerciseLibraryItem == nil,
                  !result[i].exerciseServerId.isEmpty else { continue }
            do {
                let dto = try await exerciseAPI.fetchExercise(id: result[i].exerciseServerId)
                let item = ExerciseMapper.toDomain(dto)
                result[i].exerciseLibraryItem = item
                fetchedItems.append(item)
            } catch {
                print("Failed to fetch exercise \(result[i].exerciseServerId): \(error)")
            }
        }

        // Cache newly fetched items for future lookups
        if !fetchedItems.isEmpty {
            try? await coreDataManager.cacheExercises(fetchedItems)
        }

        return result
    }
}
