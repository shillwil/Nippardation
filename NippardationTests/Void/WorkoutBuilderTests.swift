//
//  WorkoutBuilderTests.swift
//  NippardationTests
//

import Testing
import Foundation
@testable import Nippardation

@Suite("WorkoutBuilder")
struct WorkoutBuilderTests {

    @Test func parsesRepRanges() {
        #expect(WorkoutBuilder.repsRange(from: "8-12") == 8...12)
        #expect(WorkoutBuilder.repsRange(from: "5") == 5...5)
        #expect(WorkoutBuilder.repsRange(from: "12–15") == 12...15)
        #expect(WorkoutBuilder.repsRange(from: "15-10") == 15...15)
        #expect(WorkoutBuilder.repsRange(from: nil) == 8...12)
        #expect(WorkoutBuilder.repsRange(from: "AMRAP") == 8...12)
        #expect(WorkoutBuilder.repsRange(from: "0-3") == 1...3)
    }

    @Test func restRoundsToWholeMinutes() {
        #expect(WorkoutBuilder.restMinutes(from: 90) == 2)
        #expect(WorkoutBuilder.restMinutes(from: 60) == 1)
        #expect(WorkoutBuilder.restMinutes(from: 20) == 1)
        #expect(WorkoutBuilder.restMinutes(from: 180) == 3)
        #expect(WorkoutBuilder.restMinutes(from: nil) == 2)
    }

    @Test func buildsAWorkoutInTemplateOrder() {
        let template = VoidFixtures.template("Push", serverId: "t", exercises: [
            VoidFixtures.templateExercise("Overhead Press", order: 1, warmup: nil, working: 0, reps: "6-8", rest: 120, notes: "Myo-reps"),
            VoidFixtures.templateExercise("Bench Press", order: 0, warmup: 2, working: 3, reps: "8-12", rest: 90),
        ])

        let workout = WorkoutBuilder.workout(from: template)
        #expect(workout.name == "Push")
        #expect(workout.exercises.map(\.type.name) == ["Bench Press", "Overhead Press"])

        let bench = workout.exercises[0]
        #expect(bench.warmUpSets == 2)
        #expect(bench.workingSets == 3)
        #expect(bench.reps == 8...12)
        #expect(bench.rest == 2...2)
        #expect(bench.exerciseServerId == "ex_0")
        #expect(bench.example == "https://example.com/v.mp4")
        #expect(bench.lastSetIntensityTechnique == "Failure")

        let press = workout.exercises[1]
        #expect(press.warmUpSets == 0)
        #expect(press.workingSets == 1)     // never below one working set
        #expect(press.lastSetIntensityTechnique == "Myo-reps")
    }

    @Test func fallsBackToTheGivenName() {
        let template = VoidFixtures.template("  ", serverId: "t")
        #expect(WorkoutBuilder.workout(from: template, fallbackName: "Day 1").name == "Day 1")
        #expect(WorkoutBuilder.workout(from: template).name == "Workout")
    }
}
