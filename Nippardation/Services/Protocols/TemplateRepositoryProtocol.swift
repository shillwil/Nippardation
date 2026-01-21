//
//  TemplateRepositoryProtocol.swift
//  Nippardation
//
//  Phase 0: Protocol defining template repository operations
//

import Foundation

/// Protocol defining operations for managing workout templates
/// Templates are user-created workout structures
@MainActor
protocol TemplateRepositoryProtocol {

    // MARK: - Fetch Operations

    /// Fetches all templates for the current user
    /// - Parameter forceRefresh: If true, bypasses cache
    /// - Returns: List of user's templates
    func fetchTemplates(forceRefresh: Bool) async throws -> [Template]

    /// Fetches a single template by server ID
    /// - Parameters:
    ///   - serverId: The server ID of the template
    ///   - forceRefresh: If true, bypasses cache
    /// - Returns: The template if found
    func fetchTemplate(
        serverId: String,
        forceRefresh: Bool
    ) async throws -> Template

    /// Fetches public/featured templates for discovery
    /// - Parameters:
    ///   - page: Page number (1-based)
    ///   - category: Optional category filter
    /// - Returns: Paginated list of public templates
    func fetchPublicTemplates(
        page: Int,
        category: String?
    ) async throws -> PaginatedResult<Template>

    // MARK: - CRUD Operations

    /// Creates a new template
    /// - Parameter template: The template to create
    /// - Returns: The created template with server ID
    func createTemplate(_ template: Template) async throws -> Template

    /// Updates an existing template
    /// - Parameter template: The template to update
    /// - Returns: The updated template
    func updateTemplate(_ template: Template) async throws -> Template

    /// Deletes a template
    /// - Parameter serverId: The server ID of the template to delete
    func deleteTemplate(serverId: String) async throws

    /// Duplicates a template (creates a copy)
    /// - Parameter serverId: The server ID of the template to duplicate
    /// - Returns: The new duplicated template
    func duplicateTemplate(serverId: String) async throws -> Template

    // MARK: - Cache Operations

    /// Returns all cached templates
    /// - Returns: Cached templates (may be empty)
    func getCachedTemplates() -> [Template]

    /// Returns a cached template by server ID
    /// - Parameter serverId: The server ID of the template
    /// - Returns: The cached template if available
    func getCachedTemplate(serverId: String) -> Template?

    /// Saves a template to local cache (for offline creation)
    /// - Parameter template: The template to cache
    func cacheTemplate(_ template: Template) async throws

    /// Clears the template cache
    func clearCache() async throws

    // MARK: - Offline Support

    /// Returns templates that have local changes pending sync
    /// - Returns: Templates with pending changes
    func getPendingTemplates() -> [Template]

    /// Marks a template as synced
    /// - Parameter serverId: The server ID of the synced template
    func markTemplateSynced(serverId: String) async throws
}

// MARK: - Default Parameter Values

extension TemplateRepositoryProtocol {

    func fetchTemplates(forceRefresh: Bool = false) async throws -> [Template] {
        try await fetchTemplates(forceRefresh: forceRefresh)
    }

    func fetchTemplate(
        serverId: String,
        forceRefresh: Bool = false
    ) async throws -> Template {
        try await fetchTemplate(serverId: serverId, forceRefresh: forceRefresh)
    }

    func fetchPublicTemplates(
        page: Int = 1,
        category: String? = nil
    ) async throws -> PaginatedResult<Template> {
        try await fetchPublicTemplates(page: page, category: category)
    }
}
