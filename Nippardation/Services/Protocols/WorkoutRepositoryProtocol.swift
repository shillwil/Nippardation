//
//  WorkoutRepositoryProtocol.swift
//  Nippardation
//
//  Phase 0: Protocol defining workout repository operations
//

import Foundation

/// Protocol defining operations for managing completed workouts
/// Workouts are actual training sessions (vs templates which are plans)
@MainActor
protocol WorkoutRepositoryProtocol {

    // MARK: - Fetch Operations

    /// Fetches completed workouts with pagination
    /// - Parameters:
    ///   - page: Page number (1-based)
    ///   - startDate: Optional start date filter
    ///   - endDate: Optional end date filter
    ///   - forceRefresh: If true, bypasses cache
    /// - Returns: Paginated list of completed workouts
    func fetchWorkouts(
        page: Int,
        startDate: Date?,
        endDate: Date?,
        forceRefresh: Bool
    ) async throws -> PaginatedResult<TrackedWorkout>

    /// Fetches a single workout by ID
    /// - Parameters:
    ///   - id: The local UUID of the workout
    /// - Returns: The workout if found
    func fetchWorkout(id: UUID) async throws -> TrackedWorkout?

    /// Fetches workouts for a specific date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Workouts within the range
    func fetchWorkouts(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [TrackedWorkout]

    // MARK: - Save Operations

    /// Saves a completed workout locally and queues for sync
    /// - Parameter workout: The workout to save
    /// - Returns: The saved workout
    func saveWorkout(_ workout: TrackedWorkout) async throws -> TrackedWorkout

    /// Updates an existing workout
    /// - Parameter workout: The workout to update
    /// - Returns: The updated workout
    func updateWorkout(_ workout: TrackedWorkout) async throws -> TrackedWorkout

    /// Deletes a workout
    /// - Parameter id: The local UUID of the workout to delete
    func deleteWorkout(id: UUID) async throws

    // MARK: - Cache Operations

    /// Returns all cached workouts
    /// - Returns: Cached workouts (may be empty)
    func getCachedWorkouts() -> [TrackedWorkout]

    /// Returns a cached workout by ID
    /// - Parameter id: The local UUID of the workout
    /// - Returns: The cached workout if available
    func getCachedWorkout(id: UUID) -> TrackedWorkout?

    /// Returns the most recent workouts
    /// - Parameter limit: Maximum number to return
    /// - Returns: Most recent workouts
    func getRecentWorkouts(limit: Int) -> [TrackedWorkout]

    // MARK: - Statistics

    /// Gets workout count for a date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Number of workouts
    func getWorkoutCount(from startDate: Date, to endDate: Date) -> Int

    /// Gets total volume (weight x reps) for a date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Total volume in user's preferred unit
    func getTotalVolume(from startDate: Date, to endDate: Date) -> Double

    /// Gets workouts grouped by day for a date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Dictionary mapping dates to workouts
    func getWorkoutsByDay(
        from startDate: Date,
        to endDate: Date
    ) -> [Date: [TrackedWorkout]]

    // MARK: - Sync Status

    /// Returns workouts pending sync to server
    /// - Returns: Unsynced workouts
    func getPendingWorkouts() -> [TrackedWorkout]

    /// Marks a workout as synced
    /// - Parameters:
    ///   - id: The local UUID of the workout
    ///   - serverId: The server ID received after sync
    func markWorkoutSynced(id: UUID, serverId: String) async throws

    /// Returns the sync status of a workout
    /// - Parameter id: The local UUID of the workout
    /// - Returns: The sync status
    func getSyncStatus(id: UUID) -> WorkoutSyncStatus
}

// MARK: - Supporting Types

/// Sync status for a workout
enum WorkoutSyncStatus {
    /// Never synced, pending upload
    case pending
    /// Currently syncing
    case syncing
    /// Successfully synced
    case synced
    /// Sync failed, will retry
    case failed(Error)
}

// MARK: - Default Parameter Values

extension WorkoutRepositoryProtocol {

    func fetchWorkouts(
        page: Int = 1,
        startDate: Date? = nil,
        endDate: Date? = nil,
        forceRefresh: Bool = false
    ) async throws -> PaginatedResult<TrackedWorkout> {
        try await fetchWorkouts(page: page, startDate: startDate, endDate: endDate, forceRefresh: forceRefresh)
    }

    func getRecentWorkouts(limit: Int = 10) -> [TrackedWorkout] {
        getRecentWorkouts(limit: limit)
    }
}
