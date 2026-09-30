//
//  ActiveWorkoutViewModel.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/17/25.
//

import Foundation
import Combine

class ActiveWorkoutViewModel: ObservableObject {
    // Published properties that the view will observe
    @Published var workout: TrackedWorkout
    @Published var totalVolume: Double = 0
    @Published var completedSets: Int = 0
    @Published var isShowingEndWorkoutAlert = false
    @Published var volumeUnit: VolumeUnit = .pounds

    // Dependencies
    private let workoutManager = WorkoutManager.shared
    private var cancellables = Set<AnyCancellable>()

    init(workout: TrackedWorkout) {
        self.workout = workout

        // Subscribe to workout manager updates
        workoutManager.$activeWorkout
            .compactMap { $0 }
            .sink { [weak self] updatedWorkout in
                self?.workout = updatedWorkout
                self?.updateWorkoutStats()
            }
            .store(in: &cancellables)

        // Calculate initial stats
        updateWorkoutStats()
    }

    // MARK: - Workout Management

    func updateWorkout(_ newWorkout: TrackedWorkout) {
        self.workout = newWorkout
        updateWorkoutStats()
    }

    func updateExercise(at index: Int, with exercise: TrackedExercise) {
        guard index < workout.trackedExercises.count else { return }

        // Update local workout model
        workout.trackedExercises[index] = exercise

        // Update in WorkoutManager
        workoutManager.updateExercise(at: index, with: exercise)

        // Recalculate stats
        updateWorkoutStats()
    }

    /// Replaces the exercise at `index` with one selected from the library, keeping its id,
    /// sets and completion (see `TrackedExercise.swapped(to:)`).
    func swapExercise(at index: Int, to libraryItem: ExerciseLibraryItem) {
        guard index < workout.trackedExercises.count else { return }
        updateExercise(at: index, with: workout.trackedExercises[index].swapped(to: libraryItem))
    }

    /// The exercise to open after completing the one at `index`, or nil when all are done.
    func nextUnfinishedExercise(after index: Int) -> Int? {
        ExerciseProgression.nextUnfinishedIndex(after: index, in: workout.trackedExercises)
    }

    func endWorkout() {
        workoutManager.endWorkout()
    }

    // MARK: - Stats Calculation

    func updateWorkoutStats() {
        // Calculate total volume
        totalVolume = workout.trackedExercises.reduce(0.0) { exerciseSum, exercise in
            exerciseSum + exercise.trackedSets.reduce(0.0) { setSum, set in
                setSum + (Double(set.reps) * set.weight)
            }
        }

        // Count logged sets
        completedSets = workout.trackedExercises.reduce(0) { $0 + $1.trackedSets.count }
    }

    // MARK: - Volume

    var formattedTotalVolume: String {
        let convertedVolume = volumeUnit.convert(totalVolume, from: .pounds)
        return volumeUnit.format(convertedVolume)
    }
}
