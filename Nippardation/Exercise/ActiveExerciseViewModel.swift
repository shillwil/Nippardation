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
    /// True while the exercise has no video to show yet and its URL is being fetched.
    @Published var isResolvingVideo = false

    // Stats
    @Published var totalVolume: Double = 0
    @Published var totalReps: Int = 0

    // Exercise details
    let exerciseIndex: Int

    // Dependencies
    /// Receives every change, so the active workout stays saved. Nil keeps changes in this
    /// view model (tests).
    private let workoutManager: WorkoutManager?
    private let exerciseRepository: any ExerciseRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    /// The video lookup in flight. Swap movement cancels it, so a late answer for the old
    /// movement can't replace the new one's video.
    private(set) var videoLookupTask: Task<Void, Never>?

    /// - Parameters:
    ///   - template: The workout's stored template, searched first for this exercise's
    ///     targets and video. Nil uses the active workout's.
    ///   - workoutManager: Where changes are saved; nil saves nothing.
    init(
        workout: TrackedWorkout,
        exerciseIndex: Int,
        exerciseRepository: (any ExerciseRepositoryProtocol)? = nil,
        template: Workout? = nil,
        workoutManager: WorkoutManager? = WorkoutManager.shared
    ) {
        self.workout = workout
        // Clamp exerciseIndex to valid range to prevent array out of bounds crashes
        self.exerciseIndex = min(max(0, exerciseIndex), max(0, workout.trackedExercises.count - 1))
        self.exerciseRepository = exerciseRepository ?? DependencyContainer.shared.exerciseRepository
        self.workoutManager = workoutManager

        // Find matching exercise template
        findMatchingExercise(storedTemplate: template ?? workoutManager?.activeWorkoutTemplate)

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
    private func findMatchingExercise(storedTemplate: Workout?) {
        guard isValidExercise else { return }

        let trackedExercise = workout.trackedExercises[exerciseIndex]
        let exerciseName = trackedExercise.exerciseName

        // 1. Search the stored workout template first (covers program-based workouts)
        if let storedTemplate,
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

            // Meanwhile play the URL snapshotted at workout start. The video cache keeps its
            // file under the same serverId, so the demo shows at once, even with no signal;
            // the spinner is only for an exercise with nothing to show yet.
            if let snapshot = matchingExercise.flatMap({ URL(string: $0.example) }),
               let scheme = snapshot.scheme?.lowercased(),
               ["http", "https"].contains(scheme) {
                nativeVideoUrl = snapshot
            } else {
                isResolvingVideo = true
            }

            videoLookupTask = Task { [weak self] in
                guard let self else { return }
                let exercise = try? await self.exerciseRepository.fetchExercise(serverId: serverId, forceRefresh: true)
                // Swap movement cancels this lookup, and the repository answers a cancelled
                // request from its cache instead of throwing: leave the new movement alone.
                guard !Task.isCancelled else { return }
                self.isResolvingVideo = false
                // A failed fetch keeps the snapshot; a changed URL replaces it.
                if let exercise, exercise.videoUrl != self.nativeVideoUrl {
                    self.nativeVideoUrl = exercise.videoUrl
                }
            }
            return
        }

        // Fallback: name-based search (for hardcoded templates / legacy cached workouts)
        let exerciseName = workout.trackedExercises[exerciseIndex].exerciseName
        isResolvingVideo = true

        videoLookupTask = Task { [weak self] in
            guard let self else { return }
            // Video is supplementary — a failed search silently shows none
            let results = try? await self.exerciseRepository.searchExercises(query: exerciseName, limit: 5)
            // As above: after a swap, this answer is for the old movement.
            guard !Task.isCancelled else { return }
            self.isResolvingVideo = false
            if let match = results?.first(where: { $0.name.lowercased() == exerciseName.lowercased() }) {
                self.nativeVideoUrl = match.videoUrl
                self.exerciseServerId = match.serverId
            }
        }
    }

    // MARK: - Exercise Swap

    /// Replaces the current exercise with one selected from the library, preserving any
    /// already-logged sets (their snapshotted exerciseType metadata is intentionally left alone
    /// so historical set rows continue to reflect the exercise they were logged against).
    func swapExercise(to libraryItem: ExerciseLibraryItem) {
        guard isValidExercise else { return }

        // A lookup still running is for the old movement.
        videoLookupTask?.cancel()
        videoLookupTask = nil
        isResolvingVideo = false

        let updated = workout.trackedExercises[exerciseIndex].swapped(to: libraryItem)

        workout.trackedExercises[exerciseIndex] = updated
        workoutManager?.updateExercise(at: exerciseIndex, with: updated)

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
        workoutManager?.updateTrackedSet(exerciseIndex: exerciseIndex, set: set)

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
        workoutManager?.updateSet(exerciseIndex: exerciseIndex, setIndex: index, reps: reps, weight: weight, setType: setType)

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
        workoutManager?.removeTrackedSet(exerciseIndex: exerciseIndex, setIndex: index)

        // Complete needs at least one set, so deleting the last one reopens the exercise.
        if workout.trackedExercises[exerciseIndex].trackedSets.isEmpty,
           workout.trackedExercises[exerciseIndex].isCompleted {
            workout.trackedExercises[exerciseIndex].completedAt = nil
            workoutManager?.updateExercise(at: exerciseIndex, with: workout.trackedExercises[exerciseIndex])
        }

        // Recalculate stats
        updateStats()
    }

    // MARK: - Completion

    /// Marks the exercise finished (Complete exercise). Completing again keeps the first time.
    func markComplete(at date: Date = Date()) {
        guard isValidExercise,
              workout.trackedExercises[exerciseIndex].completedAt == nil else { return }

        workout.trackedExercises[exerciseIndex].completedAt = date
        workoutManager?.updateExercise(at: exerciseIndex, with: workout.trackedExercises[exerciseIndex])
    }

    /// Which bottom button leads: Add set until the target sets are logged, then Complete.
    var ctaState: ExerciseCTAState {
        let target = (matchingExercise?.warmUpSets ?? 0) + (matchingExercise?.workingSets ?? 0)
        return ExerciseCTAState(
            loggedSets: currentExercise?.trackedSets.count ?? 0,
            targetSets: target,
            hasExercise: matchingExercise != nil
        )
    }

    /// The exercise Complete moves on to, or nil when this is the last one left.
    var nextExercise: TrackedExercise? {
        ExerciseProgression
            .nextUnfinishedIndex(after: exerciseIndex, in: workout.trackedExercises)
            .map { workout.trackedExercises[$0] }
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
