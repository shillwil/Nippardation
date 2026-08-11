//
//  ActiveExerciseViewModel.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/16/25.
//

import SwiftUI
import Combine

@MainActor
class ActiveExerciseViewModel: ObservableObject {
    // Data
    @Published var workout: TrackedWorkout
    @Published var matchingExercise: Exercise?

    // Video
    @Published var nativeVideoUrl: URL?
    @Published var exerciseServerId: String?

    // Stats
    @Published var totalVolume: Double = 0
    @Published var totalReps: Int = 0

    // Exercise details
    let exerciseIndex: Int

    // Dependencies
    private let workoutManager = WorkoutManager.shared
    private let exerciseRepository: any ExerciseRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(workout: TrackedWorkout, exerciseIndex: Int, exerciseRepository: (any ExerciseRepositoryProtocol)? = nil) {
        self.workout = workout
        // Clamp exerciseIndex to valid range to prevent array out of bounds crashes
        self.exerciseIndex = min(max(0, exerciseIndex), max(0, workout.trackedExercises.count - 1))
        self.exerciseRepository = exerciseRepository ?? DependencyContainer.shared.exerciseRepository

        // Find matching exercise template
        findMatchingExercise()

        // Calculate initial stats
        updateStats()

        // Look up video URL from exercise library
        lookupExerciseVideo()
    }

    /// Indicates whether the exercise index is valid for the current workout
    var isValidExercise: Bool {
        exerciseIndex >= 0 && exerciseIndex < workout.trackedExercises.count
    }

    func updateWorkout(_ newWorkout: TrackedWorkout) {
        self.workout = newWorkout
        updateStats()
    }

    // Find the matching exercise from stored template, hardcoded templates, or construct a fallback
    private func findMatchingExercise() {
        guard isValidExercise else { return }

        let trackedExercise = workout.trackedExercises[exerciseIndex]
        let exerciseName = trackedExercise.exerciseName

        // 1. Search the stored workout template first (covers program-based workouts)
        if let storedTemplate = workoutManager.activeWorkoutTemplate,
           let match = storedTemplate.exercises.first(where: { $0.type.name == exerciseName }) {
            self.matchingExercise = match
            return
        }

        // 2. Fall back to hardcoded templates
        let allWorkouts = [upperStrength, lowerStrength, pullDay, pushDay, legDay]
        for template in allWorkouts {
            if let match = template.exercises.first(where: { $0.type.name == exerciseName }) {
                self.matchingExercise = match
                return
            }
        }

        // 3. Construct a fallback Exercise from TrackedExercise data so the UI always works
        let muscleGroups = trackedExercise.muscleGroups.compactMap { MuscleGroup(rawValue: $0) }
        self.matchingExercise = Exercise(
            type: ExerciseType(name: exerciseName, muscleGroup: muscleGroups),
            example: "",
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 0,
            workingSets: 3,
            reps: 8...12,
            rest: 2...3
        )
    }

    // MARK: - Video Lookup

    /// Looks up the exercise video URL, preferring the stored serverId from the template
    private func lookupExerciseVideo() {
        guard isValidExercise else { return }

        // If matched exercise has a serverId from the template, resolve the current
        // video URL through the repository so renamed videos don't replay stale snapshots
        if let serverId = matchingExercise?.exerciseServerId, !serverId.isEmpty {
            exerciseServerId = serverId

            Task { [weak self] in
                guard let self else { return }
                do {
                    let exercise = try await self.exerciseRepository.fetchExercise(serverId: serverId, forceRefresh: true)
                    self.nativeVideoUrl = exercise.videoUrl
                } catch {
                    // Last resort: fall back to the URL snapshotted at workout start
                    if let urlString = self.matchingExercise?.example,
                       !urlString.isEmpty,
                       let url = URL(string: urlString) {
                        self.nativeVideoUrl = url
                    }
                }
            }
            return
        }

        // Fallback: name-based search (for hardcoded templates / legacy cached workouts)
        let exerciseName = workout.trackedExercises[exerciseIndex].exerciseName

        Task { [weak self] in
            guard let self else { return }
            do {
                let results = try await self.exerciseRepository.searchExercises(query: exerciseName, limit: 5)
                if let match = results.first(where: { $0.name.lowercased() == exerciseName.lowercased() }) {
                    self.nativeVideoUrl = match.videoUrl
                    self.exerciseServerId = match.serverId
                }
            } catch {
                // Video is supplementary — silently fail
            }
        }
    }

    // MARK: - Exercise Swap

    /// Replaces the current exercise with one selected from the library, preserving any
    /// already-logged sets (their snapshotted exerciseType metadata is intentionally left alone
    /// so historical set rows continue to reflect the exercise they were logged against).
    func swapExercise(to libraryItem: ExerciseLibraryItem) {
        guard isValidExercise else { return }

        let existing = workout.trackedExercises[exerciseIndex]
        let muscleStrings = libraryItem.primaryMuscles.map { $0.rawValue }

        let updated = TrackedExercise(
            id: existing.id,
            exerciseName: libraryItem.name,
            muscleGroups: muscleStrings,
            trackedSets: existing.trackedSets,
            exerciseLibraryServerId: libraryItem.serverId
        )

        workout.trackedExercises[exerciseIndex] = updated
        workoutManager.updateExercise(at: exerciseIndex, with: updated)

        // Reset cached metadata + video so the UI reflects the new exercise
        nativeVideoUrl = nil
        exerciseServerId = libraryItem.serverId
        matchingExercise = Exercise(
            type: ExerciseType(name: libraryItem.name, muscleGroup: libraryItem.primaryMuscles),
            exerciseServerId: libraryItem.serverId,
            example: libraryItem.videoUrl?.absoluteString ?? "",
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 0,
            workingSets: 3,
            reps: 8...12,
            rest: 2...3
        )
        if let url = libraryItem.videoUrl {
            nativeVideoUrl = url
        }
    }

    // MARK: - Set Management

    // Add a set to the current exercise
    func addSet(_ set: TrackedSet) {
        guard isValidExercise else { return }

        workout.trackedExercises[exerciseIndex].trackedSets.append(set)

        // Update in WorkoutManager
        workoutManager.updateTrackedSet(exerciseIndex: exerciseIndex, set: set)

        // Recalculate stats
        updateStats()
    }

    // Update a set at the specified index
    func updateSet(at index: Int, reps: Int, weight: Double, setType: SetType) {
        guard isValidExercise,
              index >= 0,
              index < workout.trackedExercises[exerciseIndex].trackedSets.count else { return }

        var updatedSet = workout.trackedExercises[exerciseIndex].trackedSets[index]
        updatedSet.reps = reps
        updatedSet.weight = weight
        updatedSet.setType = setType
        workout.trackedExercises[exerciseIndex].trackedSets[index] = updatedSet

        // Update in WorkoutManager
        workoutManager.updateSet(exerciseIndex: exerciseIndex, setIndex: index, reps: reps, weight: weight, setType: setType)

        // Recalculate stats
        updateStats()
    }

    // Delete a set at the specified index
    func deleteSet(at index: Int) {
        guard isValidExercise,
              index >= 0,
              index < workout.trackedExercises[exerciseIndex].trackedSets.count else { return }

        workout.trackedExercises[exerciseIndex].trackedSets.remove(at: index)

        // Update in WorkoutManager
        workoutManager.removeTrackedSet(exerciseIndex: exerciseIndex, setIndex: index)

        // Recalculate stats
        updateStats()
    }

    // MARK: - Stats

    // Update workout statistics
    private func updateStats() {
        guard isValidExercise else {
            totalVolume = 0
            totalReps = 0
            return
        }

        let sets = workout.trackedExercises[exerciseIndex].trackedSets

        // Calculate total volume
        totalVolume = sets.reduce(0.0) { sum, set in
            sum + (Double(set.reps) * set.weight)
        }

        // Calculate total reps
        totalReps = sets.reduce(0) { $0 + $1.reps }
    }

    /// Returns the current tracked exercise, or nil if the workout has no exercises.
    /// Callers should check `isValidExercise` or handle the nil case gracefully.
    var currentExercise: TrackedExercise? {
        guard isValidExercise else { return nil }
        return workout.trackedExercises[exerciseIndex]
    }
}
