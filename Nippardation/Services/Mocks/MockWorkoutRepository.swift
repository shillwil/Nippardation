//
//  MockWorkoutRepository.swift
//  Nippardation
//
//  Phase 0: Mock implementation of WorkoutRepositoryProtocol for testing and previews
//

import Foundation

/// Mock implementation of WorkoutRepositoryProtocol
/// Provides sample data for testing and SwiftUI previews
@MainActor
final class MockWorkoutRepository: WorkoutRepositoryProtocol {

    // MARK: - Mock Data Storage

    private var workouts: [TrackedWorkout] = []
    private var syncedWorkouts: Set<UUID> = []
    private var shouldFail = false
    private var delay: TimeInterval = 0

    // MARK: - Initialization

    init() {
        workouts = MockWorkoutRepository.generateSampleWorkouts()
    }

    // MARK: - Configuration

    func setFailure(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }

    // MARK: - WorkoutRepositoryProtocol

    func fetchWorkouts(
        page: Int,
        startDate: Date?,
        endDate: Date?,
        forceRefresh: Bool
    ) async throws -> PaginatedResult<TrackedWorkout> {
        try await simulateNetworkCall()

        var filtered = workouts

        if let start = startDate {
            filtered = filtered.filter { $0.date >= start }
        }
        if let end = endDate {
            filtered = filtered.filter { $0.date <= end }
        }

        let sorted = filtered.sorted { $0.date > $1.date }
        let pageSize = 20
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, sorted.count)
        let pageItems = startIndex < sorted.count ? Array(sorted[startIndex..<endIndex]) : []
        let totalPages = (sorted.count + pageSize - 1) / pageSize

        return PaginatedResult(
            items: pageItems,
            page: page,
            totalPages: max(1, totalPages),
            totalItems: sorted.count
        )
    }

    func fetchWorkout(id: UUID) async throws -> TrackedWorkout? {
        try await simulateNetworkCall()
        return workouts.first { $0.id == id }
    }

    func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [TrackedWorkout] {
        try await simulateNetworkCall()
        return workouts.filter { $0.date >= startDate && $0.date <= endDate }
    }

    func saveWorkout(_ workout: TrackedWorkout) async throws -> TrackedWorkout {
        try await simulateNetworkCall()
        workouts.append(workout)
        return workout
    }

    func updateWorkout(_ workout: TrackedWorkout) async throws -> TrackedWorkout {
        try await simulateNetworkCall()
        guard let index = workouts.firstIndex(where: { $0.id == workout.id }) else {
            throw RepositoryError.notFound
        }
        workouts[index] = workout
        return workout
    }

    func deleteWorkout(id: UUID) async throws {
        try await simulateNetworkCall()
        workouts.removeAll { $0.id == id }
    }

    func getCachedWorkouts() -> [TrackedWorkout] {
        workouts.sorted { $0.date > $1.date }
    }

    func getCachedWorkout(id: UUID) -> TrackedWorkout? {
        workouts.first { $0.id == id }
    }

    func getRecentWorkouts(limit: Int) -> [TrackedWorkout] {
        Array(workouts.sorted { $0.date > $1.date }.prefix(limit))
    }

    func getWorkoutCount(from startDate: Date, to endDate: Date) -> Int {
        workouts.filter { $0.date >= startDate && $0.date <= endDate }.count
    }

    func getTotalVolume(from startDate: Date, to endDate: Date) -> Double {
        let filtered = workouts.filter { $0.date >= startDate && $0.date <= endDate }
        return filtered.reduce(0.0) { total, workout in
            total + workout.trackedExercises.reduce(0.0) { exerciseTotal, exercise in
                exerciseTotal + exercise.trackedSets.reduce(0.0) { setTotal, set in
                    let reps = Double(set.reps)
                    let weight = set.weight
                    return setTotal + (reps * weight)
                }
            }
        }
    }

    func getWorkoutsByDay(from startDate: Date, to endDate: Date) -> [Date: [TrackedWorkout]] {
        let calendar = Calendar.current
        let filtered = workouts.filter { $0.date >= startDate && $0.date <= endDate }
        return Dictionary(grouping: filtered) { workout in
            calendar.startOfDay(for: workout.date)
        }
    }

    func getPendingWorkouts() -> [TrackedWorkout] {
        workouts.filter { !syncedWorkouts.contains($0.id) }
    }

    func markWorkoutSynced(id: UUID, serverId: String) async throws {
        syncedWorkouts.insert(id)
    }

    func getSyncStatus(id: UUID) -> WorkoutSyncStatus {
        if syncedWorkouts.contains(id) {
            return .synced
        }
        return .pending
    }

    // MARK: - Helpers

    private func simulateNetworkCall() async throws {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if shouldFail {
            throw RepositoryError.networkUnavailable
        }
    }
}

// MARK: - Sample Data Generation

extension MockWorkoutRepository {

    static func generateSampleWorkouts() -> [TrackedWorkout] {
        var workouts: [TrackedWorkout] = []
        let calendar = Calendar.current
        let templates = ["Push Day", "Pull Day", "Leg Day"]

        // Generate workouts for the past 30 days
        for daysAgo in stride(from: 0, to: 30, by: 2) {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }

            let templateIndex = (daysAgo / 2) % templates.count
            let templateName = templates[templateIndex]

            let workout = createSampleWorkout(
                templateName: templateName,
                date: date
            )
            workouts.append(workout)
        }

        return workouts
    }

    private static func createSampleWorkout(templateName: String, date: Date) -> TrackedWorkout {
        let exercises: [TrackedExercise]

        switch templateName {
        case "Push Day":
            exercises = [
                createSampleExercise(name: "Bench Press", muscleGroup: .chest, sets: 4, baseWeight: 185),
                createSampleExercise(name: "Overhead Press", muscleGroup: .shoulders, sets: 3, baseWeight: 115),
                createSampleExercise(name: "Incline Dumbbell Press", muscleGroup: .chest, sets: 3, baseWeight: 70),
                createSampleExercise(name: "Lateral Raise", muscleGroup: .shoulders, sets: 3, baseWeight: 20),
                createSampleExercise(name: "Tricep Pushdown", muscleGroup: .triceps, sets: 3, baseWeight: 60)
            ]
        case "Pull Day":
            exercises = [
                createSampleExercise(name: "Deadlift", muscleGroup: .back, sets: 4, baseWeight: 315),
                createSampleExercise(name: "Pull-Ups", muscleGroup: .back, sets: 3, baseWeight: 0),
                createSampleExercise(name: "Barbell Row", muscleGroup: .back, sets: 3, baseWeight: 185),
                createSampleExercise(name: "Face Pull", muscleGroup: .shoulders, sets: 3, baseWeight: 50),
                createSampleExercise(name: "Barbell Curl", muscleGroup: .biceps, sets: 3, baseWeight: 65)
            ]
        default: // Leg Day
            exercises = [
                createSampleExercise(name: "Squat", muscleGroup: .quads, sets: 4, baseWeight: 275),
                createSampleExercise(name: "Romanian Deadlift", muscleGroup: .hamstrings, sets: 3, baseWeight: 185),
                createSampleExercise(name: "Leg Press", muscleGroup: .quads, sets: 3, baseWeight: 400),
                createSampleExercise(name: "Leg Curl", muscleGroup: .hamstrings, sets: 3, baseWeight: 90),
                createSampleExercise(name: "Calf Raise", muscleGroup: .calves, sets: 4, baseWeight: 180)
            ]
        }

        let startTime = date
        let endTime = Calendar.current.date(byAdding: .minute, value: Int.random(in: 45...90), to: startTime)
        let duration = endTime.map { $0.timeIntervalSince(startTime) }

        return TrackedWorkout(
            id: UUID(),
            userID: nil,
            date: date,
            workoutTemplate: templateName,
            duration: duration,
            trackedExercises: exercises,
            isCompleted: true,
            startTime: startTime,
            endTime: endTime
        )
    }

    private static func createSampleExercise(
        name: String,
        muscleGroup: MuscleGroup,
        sets: Int,
        baseWeight: Double
    ) -> TrackedExercise {
        let exerciseType = ExerciseType(name: name, muscleGroup: [muscleGroup])
        var trackedSets: [TrackedSet] = []

        for _ in 0..<sets {
            // Add some variation to weights and reps
            let weightVariation = Double.random(in: -10...10)
            let repsVariation = Int.random(in: -2...2)

            trackedSets.append(TrackedSet(
                reps: max(1, 8 + repsVariation),
                weight: max(0, baseWeight + weightVariation),
                setType: .working,
                exerciseType: exerciseType
            ))
        }

        return TrackedExercise(
            id: UUID(),
            exerciseName: name,
            muscleGroups: [muscleGroup.rawValue],
            trackedSets: trackedSets
        )
    }
}
