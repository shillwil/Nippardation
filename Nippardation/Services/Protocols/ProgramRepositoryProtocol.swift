//
//  ProgramRepositoryProtocol.swift
//  Nippardation
//
//  Phase 0: Protocol defining program repository operations
//

import Foundation

/// Protocol defining operations for managing workout programs
/// Programs are collections of templates in a rotation
@MainActor
protocol ProgramRepositoryProtocol {

    // MARK: - Fetch Operations

    /// Fetches all programs for the current user
    /// - Parameter forceRefresh: If true, bypasses cache
    /// - Returns: List of user's programs
    func fetchPrograms(forceRefresh: Bool) async throws -> [Program]

    /// Fetches a single program by server ID
    /// - Parameters:
    ///   - serverId: The server ID of the program
    ///   - forceRefresh: If true, bypasses cache
    /// - Returns: The program if found
    func fetchProgram(
        serverId: String,
        forceRefresh: Bool
    ) async throws -> Program

    /// Fetches public/featured programs for discovery
    /// - Parameters:
    ///   - page: Page number (1-based)
    ///   - category: Optional category filter
    /// - Returns: Paginated list of public programs
    func fetchPublicPrograms(
        page: Int,
        category: String?
    ) async throws -> PaginatedResult<Program>

    // MARK: - CRUD Operations

    /// Creates a new program
    /// - Parameter program: The program to create
    /// - Returns: The created program with server ID
    func createProgram(_ program: Program) async throws -> Program

    /// Updates an existing program
    /// - Parameter program: The program to update
    /// - Returns: The updated program
    func updateProgram(_ program: Program) async throws -> Program

    /// Deletes a program
    /// - Parameter serverId: The server ID of the program to delete
    func deleteProgram(serverId: String) async throws

    /// Deletes a program with selective template cleanup
    /// - Parameters:
    ///   - serverId: The server ID of the program to delete
    ///   - deleteTemplates: Whether to also delete associated AI templates
    ///   - keepTemplateIds: Template IDs to preserve
    ///   - programTemplateIds: All template IDs belonging to this program (for cache cleanup)
    func deleteProgram(serverId: String, deleteTemplates: Bool, keepTemplateIds: [String], programTemplateIds: [String]) async throws

    /// Duplicates a program (creates a copy)
    /// - Parameter serverId: The server ID of the program to duplicate
    /// - Returns: The new duplicated program
    func duplicateProgram(serverId: String) async throws -> Program

    // MARK: - Active Program Management

    /// Gets the currently active program
    /// - Returns: The active program if one is set
    func getActiveProgram() async throws -> Program?

    /// Sets a program as active
    /// - Parameter serverId: The server ID of the program to activate
    /// - Returns: The activated program
    func setActiveProgram(serverId: String) async throws -> Program

    /// Deactivates the current program
    func deactivateProgram() async throws

    /// Updates program progress (current day, completion count)
    /// - Parameter program: The program with updated progress
    /// - Returns: The updated program
    func updateProgramProgress(_ program: Program) async throws -> Program

    /// Advances the program to the next workout
    /// - Parameter serverId: The server ID of the program
    /// - Returns: The updated program with advanced position
    func advanceToNextWorkout(serverId: String) async throws -> Program

    /// Restarts the program from day 1 (server + cache): currentDayIndex = 0, timesCompleted = 0
    /// - Parameter serverId: The server ID of the program
    /// - Returns: The updated program
    func resetProgram(serverId: String) async throws -> Program

    // MARK: - Cache Operations

    /// Returns all cached programs
    /// - Returns: Cached programs (may be empty)
    func getCachedPrograms() -> [Program]

    /// Returns a cached program by server ID
    /// - Parameter serverId: The server ID of the program
    /// - Returns: The cached program if available
    func getCachedProgram(serverId: String) -> Program?

    /// Saves a program to local cache
    /// - Parameter program: The program to cache
    func cacheProgram(_ program: Program) async throws

    /// Clears the program cache
    func clearCache() async throws

    // MARK: - Offline Support

    /// Returns programs that have local changes pending sync
    /// - Returns: Programs with pending changes
    func getPendingPrograms() -> [Program]

    /// Marks a program as synced
    /// - Parameter serverId: The server ID of the synced program
    func markProgramSynced(serverId: String) async throws
}

// MARK: - Default Parameter Values

extension ProgramRepositoryProtocol {

    func fetchPrograms(forceRefresh: Bool = false) async throws -> [Program] {
        try await fetchPrograms(forceRefresh: forceRefresh)
    }

    func fetchProgram(
        serverId: String,
        forceRefresh: Bool = false
    ) async throws -> Program {
        try await fetchProgram(serverId: serverId, forceRefresh: forceRefresh)
    }

    func fetchPublicPrograms(
        page: Int = 1,
        category: String? = nil
    ) async throws -> PaginatedResult<Program> {
        try await fetchPublicPrograms(page: page, category: category)
    }
}
