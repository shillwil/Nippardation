//
//  MockSyncService.swift
//  Nippardation
//
//  Phase 0: Mock implementation of SyncServiceProtocol for testing and previews
//

import Foundation
import Combine

/// Mock implementation of SyncServiceProtocol
/// Simulates sync behavior for testing and previews
@MainActor
final class MockSyncService: SyncServiceProtocol {

    // MARK: - Properties

    private let stateSubject = CurrentValueSubject<SyncState, Never>(.idle)
    var syncStatePublisher: AnyPublisher<SyncState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: SyncState {
        stateSubject.value
    }

    var isSyncing: Bool {
        if case .syncing = currentState { return true }
        return false
    }

    private(set) var lastSyncTime: Date?

    // MARK: - Mock State

    private var conflicts: [SyncConflict] = []
    private var shouldFail = false
    private var simulatedDelay: TimeInterval = 1.0
    private var pendingWorkouts = 3
    private var pendingTemplates = 1
    private var pendingPrograms = 0

    // MARK: - Configuration

    func setFailure(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func setDelay(_ delay: TimeInterval) {
        self.simulatedDelay = delay
    }

    func setPendingCounts(workouts: Int, templates: Int, programs: Int) {
        self.pendingWorkouts = workouts
        self.pendingTemplates = templates
        self.pendingPrograms = programs
    }

    // MARK: - SyncServiceProtocol

    func syncAll(force: Bool) async throws {
        guard !isSyncing else { return }

        if shouldFail {
            stateSubject.send(.failed(.networkUnavailable))
            throw SyncError.networkUnavailable
        }

        let phases: [SyncPhase] = [
            .preparing,
            .uploadingWorkouts,
            .uploadingTemplates,
            .uploadingPrograms,
            .downloadingExercises,
            .downloadingTemplates,
            .downloadingPrograms,
            .finalizing
        ]

        for (index, phase) in phases.enumerated() {
            stateSubject.send(.syncing(progress: SyncProgress(
                phase: phase,
                current: index + 1,
                total: phases.count
            )))

            if simulatedDelay > 0 {
                try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000 / Double(phases.count)))
            }
        }

        lastSyncTime = Date()
        pendingWorkouts = 0
        pendingTemplates = 0
        pendingPrograms = 0
        stateSubject.send(.completed(Date()))
    }

    func syncWorkouts() async throws {
        try await performPartialSync(phase: .uploadingWorkouts)
        pendingWorkouts = 0
    }

    func syncTemplates() async throws {
        try await performPartialSync(phase: .uploadingTemplates)
        pendingTemplates = 0
    }

    func syncPrograms() async throws {
        try await performPartialSync(phase: .uploadingPrograms)
        pendingPrograms = 0
    }

    func syncWorkout(id: UUID) async throws {
        try await performPartialSync(phase: .uploadingWorkouts)
        pendingWorkouts = max(0, pendingWorkouts - 1)
    }

    func scheduleBackgroundSync() {
        // No-op for mock
    }

    func cancelBackgroundSync() {
        // No-op for mock
    }

    func getConflicts() -> [SyncConflict] {
        conflicts
    }

    func resolveConflict(conflictId: String, resolution: ConflictResolution) async throws {
        conflicts.removeAll { $0.id == conflictId }
    }

    func getPendingChangesCount() -> PendingChanges {
        PendingChanges(
            workouts: pendingWorkouts,
            templates: pendingTemplates,
            programs: pendingPrograms
        )
    }

    func resetSyncState() async throws {
        stateSubject.send(.idle)
        lastSyncTime = nil
        conflicts.removeAll()
        pendingWorkouts = 0
        pendingTemplates = 0
        pendingPrograms = 0
    }

    // MARK: - Helpers

    private func performPartialSync(phase: SyncPhase) async throws {
        if shouldFail {
            stateSubject.send(.failed(.networkUnavailable))
            throw SyncError.networkUnavailable
        }

        stateSubject.send(.syncing(progress: SyncProgress(
            phase: phase,
            current: 1,
            total: 1
        )))

        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

        lastSyncTime = Date()
        stateSubject.send(.completed(Date()))
    }

    // MARK: - Test Helpers

    /// Adds a mock conflict for testing
    func addMockConflict() {
        conflicts.append(SyncConflict(
            id: UUID().uuidString,
            type: .workout,
            localVersion: "Local workout data",
            remoteVersion: "Remote workout data",
            detectedAt: Date()
        ))
    }

    /// Simulates a sync failure
    func simulateFailure(_ error: SyncError) {
        stateSubject.send(.failed(error))
    }
}
