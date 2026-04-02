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

    // MARK: - Configuration

    private let defaultPageSize = 20

    // MARK: - Initialization

    init(
        apiService: TemplateAPIServiceProtocol,
        coreDataManager: CoreDataManager = .shared
    ) {
        self.apiService = apiService
        self.coreDataManager = coreDataManager
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
            return cached
        }

        do {
            let dto = try await apiService.fetchTemplate(id: serverId)
            let template = TemplateMapper.toDomain(dto)

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
        let createdTemplate = TemplateMapper.toDomain(dto)

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

        let updatedTemplate = TemplateMapper.toDomain(updatedDto)

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
        let template = TemplateMapper.toDomain(dto)

        // Cache the new template
        try? await coreDataManager.cacheTemplate(template)

        return template
    }

    // MARK: - Cache Operations

    func getCachedTemplates() -> [Template] {
        let cached = coreDataManager.fetchCachedTemplates()
        return cached.map { coreDataManager.toDomain($0) }
    }

    func getCachedTemplate(serverId: String) -> Template? {
        guard let cached = coreDataManager.fetchCachedTemplate(serverId: serverId) else {
            return nil
        }
        return coreDataManager.toDomain(cached)
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
}
