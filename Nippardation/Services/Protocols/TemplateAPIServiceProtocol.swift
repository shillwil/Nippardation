//
//  TemplateAPIServiceProtocol.swift
//  Nippardation
//
//  Phase 0 Extension: Protocol for workout template API operations
//
//  Implemented by: Agent A (TemplateAPIService)
//  Used by: Agent B (TemplateRepository)
//

import Foundation

/// Protocol for workout template API operations
///
/// This protocol defines the contract between the API service layer (Agent A)
/// and the repository layer (Agent B), enabling parallel development.
protocol TemplateAPIServiceProtocol: Sendable {

    /// Fetch user's templates with pagination
    /// - Parameters:
    ///   - cursor: Pagination cursor from previous response
    ///   - limit: Maximum number of results
    /// - Returns: Tuple of template DTOs and pagination info
    func fetchTemplates(
        cursor: String?,
        limit: Int
    ) async throws -> (templates: [TemplateDTO], pagination: PaginationInfo)

    /// Fetch a single template with all exercises
    /// - Parameter id: The template's server ID
    /// - Returns: Template DTO with exercises populated
    func fetchTemplate(id: String) async throws -> TemplateDTO

    /// Create a new template
    /// - Parameter request: Template creation request with name and exercises
    /// - Returns: The created template DTO
    func createTemplate(_ request: CreateTemplateRequest) async throws -> TemplateDTO

    /// Update template metadata (name, description only)
    /// - Parameters:
    ///   - id: The template's server ID
    ///   - request: Update request with fields to change
    /// - Returns: Updated template DTO
    func updateTemplate(id: String, _ request: UpdateTemplateRequest) async throws -> TemplateDTO

    /// Replace all exercises in a template
    /// - Parameters:
    ///   - id: The template's server ID
    ///   - exercises: New exercise list (replaces all existing)
    /// - Returns: Updated template DTO
    func updateTemplateExercises(
        id: String,
        _ exercises: [TemplateExerciseInput]
    ) async throws -> TemplateDTO

    /// Clone a template
    /// - Parameters:
    ///   - id: The template's server ID to clone
    ///   - newName: Optional name for the clone (defaults to "Copy of [name]")
    /// - Returns: The newly created template DTO
    func cloneTemplate(id: String, newName: String?) async throws -> TemplateDTO

    /// Delete a template
    /// - Parameter id: The template's server ID
    /// - Throws: RepositoryError.conflict if template is used in a program
    func deleteTemplate(id: String) async throws
}
