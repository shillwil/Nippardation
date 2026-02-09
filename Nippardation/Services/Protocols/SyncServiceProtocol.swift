//
//  SyncServiceProtocol.swift
//  Nippardation
//
//  Phase 0: Protocol defining sync service operations
//

import Foundation
import Combine

/// Protocol defining operations for syncing data with the server
@MainActor
protocol SyncServiceProtocol {

    // MARK: - Properties

    /// Publisher for sync state changes
    var syncStatePublisher: AnyPublisher<SyncState, Never> { get }

    /// Current sync state
    var currentState: SyncState { get }

    /// Whether a sync is currently in progress
    var isSyncing: Bool { get }

    /// Last successful sync time
    var lastSyncTime: Date? { get }

    // MARK: - Sync Operations

    /// Performs a full sync of all data types
    /// - Parameter force: If true, syncs even if recently synced
    func syncAll(force: Bool) async throws

    /// Syncs only workouts
    func syncWorkouts() async throws

    /// Syncs only templates
    func syncTemplates() async throws

    /// Syncs only programs
    func syncPrograms() async throws

    /// Syncs a specific workout by ID
    /// - Parameter workoutId: The local UUID of the workout
    func syncWorkout(id: UUID) async throws

    // MARK: - Background Sync

    /// Schedules background sync (called when app backgrounds)
    func scheduleBackgroundSync()

    /// Cancels any pending background sync
    func cancelBackgroundSync()

    // MARK: - Conflict Resolution

    /// Returns any unresolved sync conflicts
    func getConflicts() -> [SyncConflict]

    /// Resolves a conflict by choosing local or remote version
    /// - Parameters:
    ///   - conflictId: The ID of the conflict
    ///   - resolution: Which version to keep
    func resolveConflict(
        conflictId: String,
        resolution: ConflictResolution
    ) async throws

    // MARK: - Status

    /// Returns pending changes count by type
    func getPendingChangesCount() -> PendingChanges

    /// Clears sync history and resets state
    func resetSyncState() async throws
}

// MARK: - Supporting Types

/// Current state of the sync service
enum SyncState: Equatable {
    /// No sync in progress, idle
    case idle
    /// Sync is in progress
    case syncing(progress: SyncProgress)
    /// Sync completed successfully
    case completed(Date)
    /// Sync failed
    case failed(SyncError)

    static func == (lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.syncing(let lProgress), .syncing(let rProgress)):
            return lProgress == rProgress
        case (.completed(let lDate), .completed(let rDate)):
            return lDate == rDate
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

/// Progress information during sync
struct SyncProgress: Equatable {
    let phase: SyncPhase
    let current: Int
    let total: Int

    var fractionComplete: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }
}

/// Phases of the sync process
enum SyncPhase: String, Equatable {
    case preparing = "Preparing..."
    case uploadingWorkouts = "Uploading workouts..."
    case uploadingTemplates = "Uploading templates..."
    case uploadingPrograms = "Uploading programs..."
    case downloadingExercises = "Downloading exercises..."
    case downloadingTemplates = "Downloading templates..."
    case downloadingPrograms = "Downloading programs..."
    case processingConflicts = "Processing conflicts..."
    case finalizing = "Finalizing..."
}

/// Sync-specific errors
enum SyncError: LocalizedError {
    case networkUnavailable
    case unauthorized
    case serverError(String)
    case conflictsExist(count: Int)
    case partialFailure(succeeded: Int, failed: Int)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network unavailable. Your data will sync when connected."
        case .unauthorized:
            return "Please sign in to sync your data."
        case .serverError(let message):
            return "Server error: \(message)"
        case .conflictsExist(let count):
            return "\(count) conflict(s) need resolution."
        case .partialFailure(let succeeded, let failed):
            return "Sync partially completed. \(succeeded) succeeded, \(failed) failed."
        case .unknown(let error):
            return "Sync failed: \(error.localizedDescription)"
        }
    }
}

/// A sync conflict that needs resolution
struct SyncConflict: Identifiable {
    let id: String
    let entityType: ConflictType
    let entityId: String
    let resolution: String
    let detectedAt: Date

    enum ConflictType {
        case workout
        case template
        case program
    }
}

/// Resolution choice for a conflict
enum ConflictResolution {
    case keepLocal
    case keepRemote
    case merge // Future: smart merge
}

/// Count of pending changes by type
struct PendingChanges {
    let workouts: Int
    let templates: Int
    let programs: Int

    var total: Int {
        workouts + templates + programs
    }

    var isEmpty: Bool {
        total == 0
    }
}

// MARK: - Default Parameter Values

extension SyncServiceProtocol {

    func syncAll(force: Bool = false) async throws {
        try await syncAll(force: force)
    }
}
