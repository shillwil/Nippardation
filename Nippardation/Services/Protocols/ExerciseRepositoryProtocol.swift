//
//  ExerciseRepositoryProtocol.swift
//  Nippardation
//
//  Phase 0: Protocol defining exercise repository operations
//

import Foundation

/// Protocol defining operations for managing exercises
/// Implementations handle API calls, caching, and data transformation
@MainActor
protocol ExerciseRepositoryProtocol {

    // MARK: - Fetch Operations

    /// Fetches exercises from the server with optional filtering
    /// - Parameters:
    ///   - filter: Optional filter criteria
    ///   - page: Page number (1-based)
    ///   - forceRefresh: If true, bypasses cache
    /// - Returns: Paginated list of exercises
    func fetchExercises(
        filter: ExerciseFilter?,
        page: Int,
        forceRefresh: Bool
    ) async throws -> PaginatedResult<ExerciseLibraryItem>

    /// Fetches a single exercise by server ID
    /// - Parameters:
    ///   - serverId: The server ID of the exercise
    ///   - forceRefresh: If true, bypasses cache
    /// - Returns: The exercise if found
    func fetchExercise(
        serverId: String,
        forceRefresh: Bool
    ) async throws -> ExerciseLibraryItem

    /// Searches exercises by text query
    /// - Parameters:
    ///   - query: Search text
    ///   - limit: Maximum results to return
    /// - Returns: Matching exercises
    func searchExercises(
        query: String,
        limit: Int
    ) async throws -> [ExerciseLibraryItem]

    // MARK: - Cache Operations

    /// Returns cached exercises matching the filter
    /// - Parameter filter: Optional filter criteria
    /// - Returns: Cached exercises (may be empty)
    func getCachedExercises(filter: ExerciseFilter?) -> [ExerciseLibraryItem]

    /// Returns a cached exercise by server ID
    /// - Parameter serverId: The server ID of the exercise
    /// - Returns: The cached exercise if available
    func getCachedExercise(serverId: String) -> ExerciseLibraryItem?

    /// Clears the exercise cache
    func clearCache() async throws

    // MARK: - Popular/Featured

    /// Fetches popular exercises
    /// - Parameter limit: Maximum number to return
    /// - Returns: Popular exercises sorted by popularity score
    func fetchPopularExercises(limit: Int) async throws -> [ExerciseLibraryItem]

    /// Fetches exercises for a specific muscle group
    /// - Parameters:
    ///   - muscleGroup: The target muscle group
    ///   - limit: Maximum number to return
    /// - Returns: Exercises targeting that muscle group
    func fetchExercisesByMuscle(
        _ muscleGroup: MuscleGroup,
        limit: Int
    ) async throws -> [ExerciseLibraryItem]
}

// MARK: - Supporting Types

/// Paginated result wrapper
struct PaginatedResult<T> {
    let items: [T]
    let page: Int
    let totalPages: Int
    let totalItems: Int

    var hasNextPage: Bool {
        page < totalPages
    }

    var hasPreviousPage: Bool {
        page > 1
    }
}

// MARK: - Default Parameter Values

extension ExerciseRepositoryProtocol {

    func fetchExercises(
        filter: ExerciseFilter? = nil,
        page: Int = 1,
        forceRefresh: Bool = false
    ) async throws -> PaginatedResult<ExerciseLibraryItem> {
        try await fetchExercises(filter: filter, page: page, forceRefresh: forceRefresh)
    }

    func fetchExercise(
        serverId: String,
        forceRefresh: Bool = false
    ) async throws -> ExerciseLibraryItem {
        try await fetchExercise(serverId: serverId, forceRefresh: forceRefresh)
    }

    func searchExercises(
        query: String,
        limit: Int = 20
    ) async throws -> [ExerciseLibraryItem] {
        try await searchExercises(query: query, limit: limit)
    }

    func getCachedExercises(filter: ExerciseFilter? = nil) -> [ExerciseLibraryItem] {
        getCachedExercises(filter: filter)
    }

    func fetchPopularExercises(limit: Int = 10) async throws -> [ExerciseLibraryItem] {
        try await fetchPopularExercises(limit: limit)
    }

    func fetchExercisesByMuscle(
        _ muscleGroup: MuscleGroup,
        limit: Int = 20
    ) async throws -> [ExerciseLibraryItem] {
        try await fetchExercisesByMuscle(muscleGroup, limit: limit)
    }
}
