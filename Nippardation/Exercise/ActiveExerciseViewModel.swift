//
//  ActiveExerciseViewModel.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/16/25.
//

import SwiftUI
import Combine

class ActiveExerciseViewModel: ObservableObject {
    // Data
    @Published var workout: TrackedWorkout
    @Published var matchingExercise: Exercise?

    // Stats
    @Published var totalVolume: Double = 0
    @Published var totalReps: Int = 0

    // Exercise details
    let exerciseIndex: Int

    // Dependencies
    private let workoutManager = WorkoutManager.shared
    private var cancellables = Set<AnyCancellable>()

    init(workout: TrackedWorkout, exerciseIndex: Int) {
        self.workout = workout
        // Clamp exerciseIndex to valid range to prevent array out of bounds crashes
        self.exerciseIndex = min(max(0, exerciseIndex), max(0, workout.trackedExercises.count - 1))

        // Find matching exercise template
        findMatchingExercise()

        // Calculate initial stats
        updateStats()
    }

    /// Indicates whether the exercise index is valid for the current workout
    var isValidExercise: Bool {
        exerciseIndex >= 0 && exerciseIndex < workout.trackedExercises.count
    }

    func updateWorkout(_ newWorkout: TrackedWorkout) {
        self.workout = newWorkout
        updateStats()
    }

    // Find the matching exercise from the workout templates
    private func findMatchingExercise() {
        guard isValidExercise else { return }

        let exerciseName = workout.trackedExercises[exerciseIndex].exerciseName
        let allWorkouts = [upperStrength, lowerStrength, pullDay, pushDay, legDay]

        for template in allWorkouts {
            if let match = template.exercises.first(where: { $0.type.name == exerciseName }) {
                self.matchingExercise = match
                break
            }
        }
    }

    // MARK: - Video URL Properties

    /// Returns the native video URL if available for the current exercise
    /// This will be populated when ExerciseLibraryItem data with R2 URLs is available
    var nativeVideoUrl: URL? {
        // Currently returns nil as exercise templates use YouTube embeds
        // When ExerciseLibraryItem data is integrated, this will return the R2 URL
        return nil
    }

    /// Returns the exercise server ID for video caching
    /// Uses the exercise name as a fallback identifier
    var exerciseServerId: String? {
        // When ExerciseLibraryItem data is integrated, this will return the actual server ID
        return matchingExercise?.type.name
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

    // Get current tracked exercise
    // Note: exerciseIndex is clamped in init, so this should always be valid
    var currentExercise: TrackedExercise {
        precondition(isValidExercise, "Exercise index \(exerciseIndex) is out of bounds for workout with \(workout.trackedExercises.count) exercises")
        return workout.trackedExercises[exerciseIndex]
    }
}
