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
        self.exerciseIndex = exerciseIndex

        // Find matching exercise template
        findMatchingExercise()

        // Calculate initial stats
        updateStats()
    }

    func updateWorkout(_ newWorkout: TrackedWorkout) {
        self.workout = newWorkout
        updateStats()
    }

    // Find the matching exercise from the workout templates
    private func findMatchingExercise() {
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
        // Example: URL(string: "https://pub-bd9be4594e0b4c538a1e72055ea5b6fc.r2.dev/exercises/bench-press.mp4")
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
        workout.trackedExercises[exerciseIndex].trackedSets.append(set)

        // Update in WorkoutManager
        workoutManager.updateTrackedSet(exerciseIndex: exerciseIndex, set: set)

        // Recalculate stats
        updateStats()
    }

    // Update a set at the specified index
    func updateSet(at index: Int, reps: Int, weight: Double, setType: SetType) {
        guard index < workout.trackedExercises[exerciseIndex].trackedSets.count else { return }

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
        guard index < workout.trackedExercises[exerciseIndex].trackedSets.count else { return }

        workout.trackedExercises[exerciseIndex].trackedSets.remove(at: index)

        // Update in WorkoutManager
        workoutManager.removeTrackedSet(exerciseIndex: exerciseIndex, setIndex: index)

        // Recalculate stats
        updateStats()
    }

    // MARK: - Stats

    // Update workout statistics
    private func updateStats() {
        let sets = workout.trackedExercises[exerciseIndex].trackedSets

        // Calculate total volume
        totalVolume = sets.reduce(0.0) { sum, set in
            sum + (Double(set.reps) * set.weight)
        }

        // Calculate total reps
        totalReps = sets.reduce(0) { $0 + $1.reps }
    }

    // Get current tracked exercise
    var currentExercise: TrackedExercise {
        return workout.trackedExercises[exerciseIndex]
    }
}
