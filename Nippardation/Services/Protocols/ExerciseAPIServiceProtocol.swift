//
//  ExerciseAPIServiceProtocol.swift
//  Nippardation
//
//  Phase 0 Extension: Protocol for exercise-related API operations
//
//  Implemented by: Agent A (ExerciseAPIService)
//  Used by: Agent B (ExerciseRepository)
//

import Foundation

/// Protocol for exercise-related API operations
///
/// This protocol defines the contract between the API service layer (Agent A)
/// and the repository layer (Agent B), enabling parallel development.
protocol ExerciseAPIServiceProtocol: Sendable {

    /// Fetch exercises with optional filtering and pagination
    /// - Parameters:
    ///   - filters: Optional filter criteria
    ///   - cursor: Pagination cursor from previous response
    ///   - limit: Maximum number of results (default: 20, max: 100)
    /// - Returns: Tuple of exercise DTOs and pagination info
    /// - Throws: RepositoryError on failure
    func fetchExercises(
        filters: ExerciseFilters?,
        cursor: String?,
        limit: Int
    ) async throws -> (exercises: [ExerciseDTO], pagination: PaginationInfo)

    /// Fetch a single exercise by ID
    /// - Parameter id: The exercise's server ID
    /// - Returns: Exercise DTO
    /// - Throws: RepositoryError.notFound if exercise doesn't exist
    func fetchExercise(id: String) async throws -> ExerciseDTO

    /// Fetch available filter options with counts
    /// - Returns: Filter options DTO with muscle groups, equipment, etc.
    func fetchFilterOptions() async throws -> ExerciseFilterOptionsDTO

    /// Record that the user used an exercise (for "recently used" sorting)
    /// - Parameter exerciseId: The exercise's server ID
    func recordUsage(exerciseId: String) async throws
}
