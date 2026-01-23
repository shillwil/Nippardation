//
//  WorkoutRepository.swift
//  Nippardation
//
//  Concrete implementation of WorkoutRepositoryProtocol
//  Manages local workout persistence and sync status
//

import Foundation

/// Concrete implementation of WorkoutRepositoryProtocol
/// Manages local workout persistence and sync status
@MainActor
final class WorkoutRepository: WorkoutRepositoryProtocol {

    // MARK: - Dependencies

    private let coreDataManager: CoreDataManager

    // MARK: - Configuration

    private let defaultPageSize = 20

    // MARK: - Initialization

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    // MARK: - Fetch Operations

    func fetchWorkouts(
        page: Int,
        startDate: Date?,
        endDate: Date?,
        forceRefresh: Bool
    ) async throws -> PaginatedResult<TrackedWorkout> {
        // Validate page parameter to prevent negative fetch offsets
        let validPage = max(1, page)

        // Workouts are local-first, so we always use Core Data
        let cdWorkouts = coreDataManager.fetchWorkouts(
            page: validPage,
            limit: defaultPageSize,
            startDate: startDate,
            endDate: endDate
        )

        let workouts = cdWorkouts.map { convertToTrackedWorkout($0) }

        // Get total count for pagination
        let totalCount = coreDataManager.getWorkoutCount(startDate: startDate, endDate: endDate)
        let totalPages = (totalCount + defaultPageSize - 1) / defaultPageSize

        return PaginatedResult(
            items: workouts,
            page: validPage,
            totalPages: max(1, totalPages),
            totalItems: totalCount
        )
    }

    func fetchWorkout(id: UUID) async throws -> TrackedWorkout? {
        return coreDataManager.fetchTrackedWorkout(id: id)
    }

    func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [TrackedWorkout] {
        let cdWorkouts = coreDataManager.fetchWorkouts(from: startDate, to: endDate)
        return cdWorkouts.map { convertToTrackedWorkout($0) }
    }

    // MARK: - Save Operations

    func saveWorkout(_ workout: TrackedWorkout) async throws -> TrackedWorkout {
        // Use existing CoreDataManager method
        coreDataManager.saveTrackedWorkout(workout)

        // Return the workout (it's now saved)
        return workout
    }

    func updateWorkout(_ workout: TrackedWorkout) async throws -> TrackedWorkout {
        // Use atomic update to prevent data loss - delete and save happen in single transaction
        try await coreDataManager.updateTrackedWorkout(workout)
        return workout
    }

    func deleteWorkout(id: UUID) async throws {
        coreDataManager.deleteTrackedWorkout(id: id)
    }

    // MARK: - Cache Operations

    func getCachedWorkouts() -> [TrackedWorkout] {
        return coreDataManager.fetchTrackedWorkouts()
    }

    func getCachedWorkout(id: UUID) -> TrackedWorkout? {
        return coreDataManager.fetchTrackedWorkout(id: id)
    }

    func getRecentWorkouts(limit: Int) -> [TrackedWorkout] {
        let all = coreDataManager.fetchTrackedWorkouts()
        return Array(all.prefix(limit))
    }

    // MARK: - Statistics

    func getWorkoutCount(from startDate: Date, to endDate: Date) -> Int {
        let workouts = coreDataManager.fetchWorkouts(from: startDate, to: endDate)
        return workouts.count
    }

    func getTotalVolume(from startDate: Date, to endDate: Date) -> Double {
        let cdWorkouts = coreDataManager.fetchWorkouts(from: startDate, to: endDate)

        var totalVolume: Double = 0
        for cdWorkout in cdWorkouts {
            for cdExercise in cdWorkout.trackedExercisesArray {
                for cdSet in cdExercise.trackedSetsArray {
                    totalVolume += Double(cdSet.reps) * cdSet.weight
                }
            }
        }

        return totalVolume
    }

    func getWorkoutsByDay(from startDate: Date, to endDate: Date) -> [Date: [TrackedWorkout]] {
        let cdWorkouts = coreDataManager.fetchWorkouts(from: startDate, to: endDate)
        let workouts = cdWorkouts.map { convertToTrackedWorkout($0) }

        // Group by day
        var grouped: [Date: [TrackedWorkout]] = [:]
        let calendar = Calendar.current

        for workout in workouts {
            let dayStart = calendar.startOfDay(for: workout.date)
            if grouped[dayStart] == nil {
                grouped[dayStart] = []
            }
            grouped[dayStart]?.append(workout)
        }

        return grouped
    }

    // MARK: - Sync Status

    func getPendingWorkouts() -> [TrackedWorkout] {
        let cdWorkouts = coreDataManager.fetchUnsyncedWorkouts()
        return cdWorkouts.map { convertToTrackedWorkout($0) }
    }

    func markWorkoutSynced(id: UUID, serverId: String) async throws {
        try await coreDataManager.markWorkoutSynced(localId: id, serverId: serverId)
    }

    func getSyncStatus(id: UUID) -> WorkoutSyncStatus {
        return coreDataManager.getWorkoutSyncStatus(localId: id)
    }

    // MARK: - Private Helpers

    /// Convert CDTrackedWorkout to TrackedWorkout
    private func convertToTrackedWorkout(_ cdWorkout: CDTrackedWorkout) -> TrackedWorkout {
        let exercises = cdWorkout.trackedExercisesArray

        let trackedExercises = exercises.map { cdExercise -> TrackedExercise in
            let sets = cdExercise.trackedSetsArray

            let trackedSets = sets.map { cdSet -> TrackedSet in
                let muscleGroups = cdSet.exerciseTypeMuscleGroups?.compactMap {
                    MuscleGroup(rawValue: $0)
                } ?? []

                let exerciseType = ExerciseType(
                    name: cdSet.exerciseTypeName ?? "",
                    muscleGroup: muscleGroups
                )

                return TrackedSet(
                    reps: Int(cdSet.reps),
                    weight: cdSet.weight,
                    setType: cdSet.setType == 0 ? .warmup : .working,
                    exerciseType: exerciseType
                )
            }

            let muscleGroups = cdExercise.muscleGroups?.compactMap { $0 } ?? []

            return TrackedExercise(
                id: cdExercise.id ?? UUID(),
                exerciseName: cdExercise.exerciseName ?? "",
                muscleGroups: muscleGroups,
                trackedSets: trackedSets
            )
        }

        return TrackedWorkout(
            id: cdWorkout.id ?? UUID(),
            userID: cdWorkout.userID,
            date: cdWorkout.date ?? Date(),
            workoutTemplate: cdWorkout.workoutTemplate ?? "",
            duration: cdWorkout.duration,
            trackedExercises: trackedExercises,
            isCompleted: cdWorkout.isCompleted,
            startTime: cdWorkout.startTime,
            endTime: cdWorkout.endTime
        )
    }
}
