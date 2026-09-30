//
//  TrackedExerciseCompletionTests.swift
//  NippardationTests
//
//  The explicit "completed" flag on a tracked exercise: its meaning, its survival across a
//  swap, and backward compatibility with workouts cached by earlier builds.
//

import Testing
import Foundation
@testable import Nippardation

@Suite("Tracked exercise completion")
struct TrackedExerciseCompletionTests {

    @Test func loggingSetsDoesNotCompleteAnExercise() {
        var exercise = VoidFixtures.exercise("Bench Press", sets: [VoidFixtures.set(8, 135)])
        #expect(exercise.hasLoggedSets)
        #expect(exercise.isCompleted == false)

        exercise.completedAt = VoidFixtures.now
        #expect(exercise.isCompleted)
    }

    /// Exactly what the previous build wrote to the active-workout cache: no completedAt key.
    /// It must still decode, or WorkoutCacheManager clears the workout in progress.
    @Test func decodesAnExerciseCachedByAnEarlierBuild() throws {
        let json = """
        {
          "id": "6B1E4E7C-6C2A-4C55-9F0B-2B2F9A0E6D11",
          "exerciseName": "Bench Press",
          "muscleGroups": ["chest"],
          "trackedSets": [
            { "reps": 8, "weight": 135, "exerciseTypeName": "Bench Press",
              "exerciseTypeMuscleGroups": ["chest"], "setType": "working" }
          ]
        }
        """

        let exercise = try JSONDecoder().decode(TrackedExercise.self, from: Data(json.utf8))

        #expect(exercise.exerciseName == "Bench Press")
        #expect(exercise.trackedSets.count == 1)
        #expect(exercise.completedAt == nil)
        #expect(exercise.isCompleted == false)
    }

    @Test func aCachedWorkoutRoundTripsItsCompletion() throws {
        var done = VoidFixtures.exercise("Bench Press", sets: [VoidFixtures.set(8, 135)])
        done.completedAt = VoidFixtures.now
        let open = VoidFixtures.exercise("Incline Press", sets: [])
        let workout = VoidFixtures.workout(on: VoidFixtures.now, exercises: [done, open], completed: false)

        // The same plain coders WorkoutCacheManager uses.
        let data = try JSONEncoder().encode(workout)
        let decoded = try JSONDecoder().decode(TrackedWorkout.self, from: data)

        #expect(decoded.trackedExercises[0].completedAt == VoidFixtures.now)
        #expect(decoded.trackedExercises[1].completedAt == nil)
    }

    @Test func anUnfinishedExerciseWritesNoCompletionKey() throws {
        let exercise = VoidFixtures.exercise("Bench Press", sets: [])
        let json = String(decoding: try JSONEncoder().encode(exercise), as: UTF8.self)
        #expect(!json.contains("completedAt"))
    }

    @Test func swappingKeepsTheSlotItsSetsAndItsCompletion() {
        var original = VoidFixtures.exercise("Bench Press", sets: [VoidFixtures.set(8, 135), VoidFixtures.set(6, 155)])
        original.completedAt = VoidFixtures.now
        let replacement = VoidFixtures.libraryItem("Dumbbell Press", serverId: "ex_db_press")

        let swapped = original.swapped(to: replacement)

        #expect(swapped.id == original.id)
        #expect(swapped.exerciseName == "Dumbbell Press")
        #expect(swapped.exerciseLibraryServerId == "ex_db_press")
        #expect(swapped.muscleGroups == replacement.primaryMuscles.map { $0.rawValue })
        #expect(swapped.trackedSets == original.trackedSets)
        #expect(swapped.completedAt == original.completedAt)
    }
}
