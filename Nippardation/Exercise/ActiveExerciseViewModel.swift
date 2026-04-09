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

    /// Looks up the ExerciseLibraryItem from the repository to get the video URL
    private func lookupExerciseVideo() {
        guard isValidExercise else { return }
        let exerciseName = workout.trackedExercises[exerciseIndex].exerciseName

        // Set fallback server ID from template name
        exerciseServerId = matchingExercise?.type.name

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let results = try await self.exerciseRepository.searchExercises(query: exerciseName, limit: 5)
                // Find exact name match first, fall back to first result
                let match = results.first(where: { $0.name.lowercased() == exerciseName.lowercased() })
                    ?? results.first
                if let match = match {
                    self.nativeVideoUrl = match.videoUrl
                    self.exerciseServerId = match.serverId
                }
            } catch {
                // Silently fail — video is supplementary, not critical
            }
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
