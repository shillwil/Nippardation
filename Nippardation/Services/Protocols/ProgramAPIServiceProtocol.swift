//
//  ProgramAPIServiceProtocol.swift
//  Nippardation
//
//  Phase 0 Extension: Protocol for workout program API operations
//
//  Implemented by: Agent A (ProgramAPIService)
//  Used by: Agent B (ProgramRepository)
//

import Foundation

/// Protocol for workout program API operations
///
/// This protocol defines the contract between the API service layer (Agent A)
/// and the repository layer (Agent B), enabling parallel development.
protocol ProgramAPIServiceProtocol: Sendable {

    // MARK: - CRUD Operations

    /// Fetch user's programs with pagination
    /// - Parameters:
    ///   - cursor: Pagination cursor from previous response
    ///   - limit: Maximum number of results
    /// - Returns: Tuple of program DTOs and pagination info
    func fetchPrograms(
        cursor: String?,
        limit: Int
    ) async throws -> (programs: [ProgramDTO], pagination: PaginationInfo)

    /// Fetch a single program with all workouts
    /// - Parameter id: The program's server ID
    /// - Returns: Program DTO with workouts populated
    func fetchProgram(id: String) async throws -> ProgramDTO

    /// Fetch the user's currently active program
    /// - Returns: Active program DTO with next workout info, or nil if none active
    func fetchActiveProgram() async throws -> ActiveProgramDTO?

    /// Create a new program
    /// - Parameter request: Program creation request
    /// - Returns: The created program DTO
    func createProgram(_ request: CreateProgramRequest) async throws -> ProgramDTO

    /// Update program metadata
    /// - Parameters:
    ///   - id: The program's server ID
    ///   - request: Update request with fields to change
    /// - Returns: Updated program DTO
    func updateProgram(id: String, _ request: UpdateProgramRequest) async throws -> ProgramDTO

    /// Replace all workouts in a program
    /// - Parameters:
    ///   - id: The program's server ID
    ///   - workouts: New workout list (replaces all existing)
    /// - Returns: Updated program DTO
    func updateProgramWorkouts(
        id: String,
        _ workouts: [ProgramWorkoutInput]
    ) async throws -> ProgramDTO

    /// Delete a program
    /// - Parameter id: The program's server ID
    /// - Note: Workouts cascade delete, templates are preserved
    func deleteProgram(id: String) async throws

    // MARK: - State Management

    /// Set a program as active (deactivates any other active program)
    /// - Parameter id: The program's server ID
    /// - Returns: Updated program DTO with isActive = true
    func activateProgram(id: String) async throws -> ProgramDTO

    /// Remove active status from a program
    /// - Parameter id: The program's server ID
    /// - Returns: Updated program DTO with isActive = false
    func deactivateProgram(id: String) async throws -> ProgramDTO

    /// Advance to the next day in the program rotation
    /// - Parameter id: The program's server ID
    /// - Returns: Updated program DTO with incremented currentDayIndex
    /// - Note: Wraps around and increments timesCompleted when cycling
    func advanceProgram(id: String) async throws -> ProgramDTO

    /// Reset program progress to day 0
    /// - Parameter id: The program's server ID
    /// - Returns: Updated program DTO with currentDayIndex = 0, timesCompleted = 0
    func resetProgram(id: String) async throws -> ProgramDTO
}
