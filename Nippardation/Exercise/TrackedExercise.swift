//
//  TrackedExercise.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/11/25.
//

import Foundation

struct TrackedExercise: Identifiable, Codable {
    var id = UUID()
    var exerciseName: String
    var muscleGroups: [String]  // Store as strings for Codable compliance
    var trackedSets: [TrackedSet]
    var exerciseLibraryServerId: String? = nil
    /// When the person tapped Complete exercise. Optional on purpose: workouts cached by
    /// older builds have no such key, and a non-optional field would fail to decode them
    /// (WorkoutCacheManager then clears the cache, losing the workout in progress).
    var completedAt: Date? = nil

    /// Finished on purpose: the person tapped Complete exercise.
    var isCompleted: Bool {
        completedAt != nil
    }

    /// At least one set is logged; the exercise may still be in progress.
    var hasLoggedSets: Bool {
        !trackedSets.isEmpty
    }

    /// The same slot after a mid-workout swap: new movement, same id, and the sets and
    /// completion already logged against it (their snapshotted exerciseType metadata is
    /// intentionally left alone so history rows still show what they were logged as).
    func swapped(to libraryItem: ExerciseLibraryItem) -> TrackedExercise {
        var updated = self
        updated.exerciseName = libraryItem.name
        updated.muscleGroups = libraryItem.primaryMuscles.map { $0.rawValue }
        updated.exerciseLibraryServerId = libraryItem.serverId
        return updated
    }
}
