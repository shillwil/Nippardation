//
//  MockSyncAPIService.swift
//  Nippardation
//
//  Phase 0 Extension: Mock implementation of SyncAPIServiceProtocol for testing and development
//

import Foundation

/// Mock implementation of SyncAPIServiceProtocol for testing and development
final class MockSyncAPIService: SyncAPIServiceProtocol, @unchecked Sendable {

    // MARK: - Test Configuration

    var shouldThrowError = false
    var errorToThrow: RepositoryError = .networkUnavailable
    var fetchDelay: TimeInterval = 0.2

    /// Custom response to return (if nil, returns default success)
    var customResponse: SyncResponseDTO?

    /// Conflicts to include in response
    var conflicts: [SyncAPIConflictDTO] = []

    /// Server workouts to return (simulates data from other devices)
    var serverWorkouts: [WorkoutSyncDTO] = []

    // MARK: - Call Tracking

    private(set) var syncCallCount = 0
    private(set) var lastPayload: SyncRequestDTO?

    // MARK: - Protocol Implementation

    func sync(payload: SyncRequestDTO) async throws -> SyncResponseDTO {
        syncCallCount += 1
        lastPayload = payload

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        if let custom = customResponse {
            return custom
        }

        // Build default response
        let now = ISO8601DateFormatter().string(from: Date())
        return SyncResponseDTO(
            syncedAt: now,
            conflicts: conflicts.isEmpty ? nil : conflicts,
            serverData: serverWorkouts.isEmpty ? nil : ServerSyncDataDTO(
                workouts: serverWorkouts,
                lastServerSync: now
            ),
            stats: SyncStatsDTO(
                uploaded: payload.workouts.count,
                downloaded: serverWorkouts.count,
                conflicts: conflicts.count
            )
        )
    }

    /// Reset all tracking state
    func reset() {
        syncCallCount = 0
        lastPayload = nil
        shouldThrowError = false
        customResponse = nil
        conflicts = []
        serverWorkouts = []
    }
}
