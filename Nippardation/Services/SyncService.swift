//
//  SyncService.swift
//  Nippardation
//
//  Concrete implementation of SyncServiceProtocol
//  Handles bidirectional sync between local Core Data and server
//

import Foundation
import Combine

/// Concrete implementation of SyncServiceProtocol
/// Handles bidirectional sync between local Core Data and server
@MainActor
final class SyncService: SyncServiceProtocol {

    // MARK: - Dependencies

    private let apiService: SyncAPIServiceProtocol
    private let workoutRepository: WorkoutRepositoryProtocol
    private let templateRepository: TemplateRepositoryProtocol
    private let programRepository: ProgramRepositoryProtocol
    private let coreDataManager: CoreDataManager

    // MARK: - Published State

    private let _syncState = CurrentValueSubject<SyncState, Never>(.idle)

    var syncStatePublisher: AnyPublisher<SyncState, Never> {
        _syncState.eraseToAnyPublisher()
    }

    var currentState: SyncState {
        _syncState.value
    }

    var isSyncing: Bool {
        if case .syncing = _syncState.value {
            return true
        }
        return false
    }

    var lastSyncTime: Date? {
        coreDataManager.getLastSyncTimestamp()
    }

    // MARK: - State

    private var conflicts: [SyncConflict] = []

    /// Device ID for sync (persisted across sessions)
    private var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: "syncDeviceId") {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "syncDeviceId")
        return newId
    }

    // MARK: - Configuration

    /// Minimum time between automatic syncs (seconds)
    private let minSyncInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    init(
        apiService: SyncAPIServiceProtocol,
        workoutRepository: WorkoutRepositoryProtocol,
        templateRepository: TemplateRepositoryProtocol,
        programRepository: ProgramRepositoryProtocol,
        coreDataManager: CoreDataManager = .shared
    ) {
        self.apiService = apiService
        self.workoutRepository = workoutRepository
        self.templateRepository = templateRepository
        self.programRepository = programRepository
        self.coreDataManager = coreDataManager
    }

    // MARK: - Sync Operations

    func syncAll(force: Bool) async throws {
        // Check if sync is needed
        guard force || isSyncNeeded() else {
            return
        }

        // Prevent concurrent syncs
        guard !isSyncing else {
            throw SyncError.unknown(NSError(domain: "SyncService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sync already in progress"]))
        }

        _syncState.send(.syncing(progress: SyncProgress(phase: .preparing, current: 0, total: 100)))

        do {
            // Sync workouts
            _syncState.send(.syncing(progress: SyncProgress(phase: .uploadingWorkouts, current: 20, total: 100)))
            try await syncWorkouts()

            // Sync templates
            _syncState.send(.syncing(progress: SyncProgress(phase: .uploadingTemplates, current: 40, total: 100)))
            try await syncTemplates()

            // Sync programs
            _syncState.send(.syncing(progress: SyncProgress(phase: .uploadingPrograms, current: 60, total: 100)))
            try await syncPrograms()

            // Finalize
            _syncState.send(.syncing(progress: SyncProgress(phase: .finalizing, current: 90, total: 100)))

            // Update last sync timestamp
            coreDataManager.setLastSyncTimestamp(Date())

            _syncState.send(.completed(Date()))

        } catch {
            let syncError: SyncError
            if let repoError = error as? RepositoryError {
                switch repoError {
                case .networkUnavailable:
                    syncError = .networkUnavailable
                case .unauthorized:
                    syncError = .unauthorized
                case .serverError(_, let message):
                    syncError = .serverError(message ?? "Unknown server error")
                default:
                    syncError = .unknown(error)
                }
            } else {
                syncError = .unknown(error)
            }

            _syncState.send(.failed(syncError))
            throw syncError
        }
    }

    func syncWorkouts() async throws {
        // Get pending workouts
        let pendingWorkouts = workoutRepository.getPendingWorkouts()

        guard !pendingWorkouts.isEmpty else {
            return
        }

        // Build sync payload
        let workoutDTOs = pendingWorkouts.map { workout -> WorkoutCreateDTO in
            let exerciseDTOs = workout.trackedExercises.enumerated().map { (index, exercise) -> WorkoutExerciseCreateDTO in
                let setDTOs = exercise.trackedSets.enumerated().map { (setIndex, set) -> WorkoutSetCreateDTO in
                    WorkoutSetCreateDTO(
                        clientId: set.id.uuidString,
                        setNumber: setIndex + 1,
                        setType: set.setType.rawValue,
                        targetReps: nil,
                        completedReps: set.reps,
                        weight: set.weight,
                        weightUnit: "lbs",
                        rpe: nil,
                        notes: nil
                    )
                }

                return WorkoutExerciseCreateDTO(
                    clientId: exercise.id.uuidString,
                    exerciseId: nil,
                    exerciseName: exercise.exerciseName,
                    orderIndex: index,
                    sets: setDTOs,
                    notes: nil
                )
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            return WorkoutCreateDTO(
                clientId: workout.id.uuidString,
                templateId: nil,
                templateName: workout.workoutTemplate,
                startedAt: formatter.string(from: workout.startTime ?? workout.date),
                completedAt: workout.endTime.map { formatter.string(from: $0) },
                durationSeconds: workout.duration.map { Int($0) },
                notes: nil,
                exercises: exerciseDTOs
            )
        }

        let payload = SyncRequestDTO(
            deviceId: deviceId,
            lastSyncedAt: lastSyncTime.map { ISO8601DateFormatter().string(from: $0) },
            workouts: workoutDTOs
        )

        // Send to server
        let response = try await apiService.sync(payload: payload)

        // Process response
        if response.success {
            // Mark workouts as synced
            // Note: The response should contain server IDs for the synced workouts
            // For now, we'll mark them as synced with their client IDs
            for workout in pendingWorkouts {
                try? await workoutRepository.markWorkoutSynced(
                    id: workout.id,
                    serverId: workout.id.uuidString // Use client ID until we get server ID
                )
            }
        }

        // Handle conflicts - deduplicate to avoid accumulation across retries
        if let responseConflicts = response.conflicts, !responseConflicts.isEmpty {
            for conflict in responseConflicts {
                // Only add if this conflict ID doesn't already exist
                if !conflicts.contains(where: { $0.id == conflict.clientId }) {
                    conflicts.append(SyncConflict(
                        id: conflict.clientId,
                        type: .workout,
                        localVersion: conflict.clientId,
                        remoteVersion: conflict.serverId as Any,
                        detectedAt: Date()
                    ))
                }
            }
        }
    }

    func syncTemplates() async throws {
        // Sync pending templates
        let pendingTemplates = templateRepository.getPendingTemplates()

        for template in pendingTemplates {
            do {
                let syncedServerId: String
                if template.serverId.isEmpty {
                    // New template - create on server and get assigned serverId
                    let createdTemplate = try await templateRepository.createTemplate(template)
                    syncedServerId = createdTemplate.serverId
                } else {
                    // Existing template - update on server
                    let updatedTemplate = try await templateRepository.updateTemplate(template)
                    syncedServerId = updatedTemplate.serverId
                }
                // Only mark as synced if the operation succeeded, using the correct serverId
                try await templateRepository.markTemplateSynced(serverId: syncedServerId)
            } catch {
                // Log error but continue with other templates
                print("Failed to sync template \(template.id): \(error)")
            }
        }

        // Refresh from server
        _ = try? await templateRepository.fetchTemplates(forceRefresh: true)
    }

    func syncPrograms() async throws {
        // Sync pending programs
        let pendingPrograms = programRepository.getPendingPrograms()

        for program in pendingPrograms {
            do {
                let syncedServerId: String
                if program.serverId.isEmpty {
                    // New program - create on server and get assigned serverId
                    let createdProgram = try await programRepository.createProgram(program)
                    syncedServerId = createdProgram.serverId
                } else {
                    // Existing program - update on server
                    let updatedProgram = try await programRepository.updateProgram(program)
                    syncedServerId = updatedProgram.serverId
                }
                // Only mark as synced if the operation succeeded, using the correct serverId
                try await programRepository.markProgramSynced(serverId: syncedServerId)
            } catch {
                // Log error but continue with other programs
                print("Failed to sync program \(program.id): \(error)")
            }
        }

        // Refresh from server
        _ = try? await programRepository.fetchPrograms(forceRefresh: true)
    }

    func syncWorkout(id: UUID) async throws {
        guard let workout = workoutRepository.getCachedWorkout(id: id) else {
            throw RepositoryError.notFound
        }

        // Build sync payload for single workout
        let exerciseDTOs = workout.trackedExercises.enumerated().map { (index, exercise) -> WorkoutExerciseCreateDTO in
            let setDTOs = exercise.trackedSets.enumerated().map { (setIndex, set) -> WorkoutSetCreateDTO in
                WorkoutSetCreateDTO(
                    clientId: set.id.uuidString,
                    setNumber: setIndex + 1,
                    setType: set.setType.rawValue,
                    targetReps: nil,
                    completedReps: set.reps,
                    weight: set.weight,
                    weightUnit: "lbs",
                    rpe: nil,
                    notes: nil
                )
            }

            return WorkoutExerciseCreateDTO(
                clientId: exercise.id.uuidString,
                exerciseId: nil,
                exerciseName: exercise.exerciseName,
                orderIndex: index,
                sets: setDTOs,
                notes: nil
            )
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let workoutDTO = WorkoutCreateDTO(
            clientId: workout.id.uuidString,
            templateId: nil,
            templateName: workout.workoutTemplate,
            startedAt: formatter.string(from: workout.startTime ?? workout.date),
            completedAt: workout.endTime.map { formatter.string(from: $0) },
            durationSeconds: workout.duration.map { Int($0) },
            notes: nil,
            exercises: exerciseDTOs
        )

        let payload = SyncRequestDTO(
            deviceId: deviceId,
            lastSyncedAt: nil,
            workouts: [workoutDTO]
        )

        let response = try await apiService.sync(payload: payload)

        if response.success {
            try? await workoutRepository.markWorkoutSynced(
                id: workout.id,
                serverId: workout.id.uuidString
            )
        }
    }

    // MARK: - Background Sync

    func scheduleBackgroundSync() {
        // Background sync scheduling is handled by the app lifecycle
        // This is a placeholder for BackgroundTasks framework integration
    }

    func cancelBackgroundSync() {
        // Cancel any scheduled background sync tasks
    }

    // MARK: - Conflict Resolution

    func getConflicts() -> [SyncConflict] {
        return conflicts
    }

    func resolveConflict(conflictId: String, resolution: ConflictResolution) async throws {
        guard let index = conflicts.firstIndex(where: { $0.id == conflictId }) else {
            throw RepositoryError.notFound
        }

        let conflict = conflicts[index]

        switch resolution {
        case .keepLocal:
            // Force push local version to server
            if case .workout = conflict.type {
                if let id = UUID(uuidString: conflictId) {
                    try await syncWorkout(id: id)
                }
            }

        case .keepRemote:
            // Discard local changes - the server version is already in place
            // Just remove the conflict
            break

        case .merge:
            // Future: implement smart merge
            // For now, treat as keepLocal
            if case .workout = conflict.type {
                if let id = UUID(uuidString: conflictId) {
                    try await syncWorkout(id: id)
                }
            }
        }

        // Remove resolved conflict
        conflicts.remove(at: index)
    }

    // MARK: - Status

    func getPendingChangesCount() -> PendingChanges {
        return coreDataManager.getPendingChangesCount()
    }

    func resetSyncState() async throws {
        conflicts.removeAll()
        _syncState.send(.idle)
        UserDefaults.standard.removeObject(forKey: "lastSyncTimestamp")
    }

    // MARK: - Private Helpers

    private func isSyncNeeded() -> Bool {
        guard let lastSync = lastSyncTime else {
            return true
        }
        return Date().timeIntervalSince(lastSync) > minSyncInterval
    }
}
