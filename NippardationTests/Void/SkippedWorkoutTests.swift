//
//  SkippedWorkoutTests.swift
//  NippardationTests
//
//  The skipped-vs-done distinction: the rotation state, and the store behind it.
//

import Testing
import Foundation
@testable import Nippardation

@Suite("Skipped workouts")
@MainActor
struct SkippedWorkoutTests {

    private let calendar = VoidFixtures.calendar
    private let now = VoidFixtures.now // Wed 2026-09-09

    // MARK: - Rotation state

    @Test func skippedDayReadsSkippedNotDoneAndNotLater() {
        let program = VoidFixtures.pplProgram(currentDayIndex: 1)
        let push = program.workouts.first { $0.dayNumber == 0 }!
        let skip = VoidFixtures.skip(push, program: program, on: VoidFixtures.date(2026, 9, 7))

        let rows = PlanRotationBuilder.rows(
            for: program,
            completedWorkouts: [],
            skippedWorkouts: [skip],
            now: now,
            calendar: calendar
        )

        #expect(rows[0].state == .skipped)
        #expect(rows[0].isSkipped)
        #expect(rows[0].isDone == false)
        #expect(rows[0].isSettled)
        #expect(rows[0].eyebrow == "MON · SKIPPED")   // the skip's own date, like a completion
        #expect(rows[0].accessibilityLabel.hasSuffix("skipped"))
        #expect(rows[1].state == .next)
        #expect(rows[2].state == .later)
    }

    @Test func completionWinsOverASkipForTheSameDay() {
        // Skipped, then actually done later in the week: it is done, not skipped.
        let program = VoidFixtures.pplProgram(currentDayIndex: 1)
        let push = program.workouts.first { $0.dayNumber == 0 }!
        let skip = VoidFixtures.skip(push, program: program, on: VoidFixtures.date(2026, 9, 7))
        let done = VoidFixtures.workout(name: "Push", on: VoidFixtures.date(2026, 9, 8))

        let rows = PlanRotationBuilder.rows(
            for: program,
            completedWorkouts: [done],
            skippedWorkouts: [skip],
            now: now,
            calendar: calendar
        )

        #expect(rows[0].state == .done)
        #expect(rows[0].eyebrow == "TUE · DONE")
    }

    @Test func lastWeeksSkipDoesNotMarkThisWeek() {
        let program = VoidFixtures.pplProgram(currentDayIndex: 1)
        let push = program.workouts.first { $0.dayNumber == 0 }!
        let old = VoidFixtures.skip(push, program: program, on: VoidFixtures.date(2026, 9, 5))

        let rows = PlanRotationBuilder.rows(
            for: program,
            completedWorkouts: [],
            skippedWorkouts: [old],
            now: now,
            calendar: calendar
        )

        #expect(rows[0].state == .later)
    }

    @Test func eachSkipMarksAtMostOneRow() {
        // Upper / Lower / Upper: one skip of the shared template marks only the first row.
        let upper = VoidFixtures.template("Upper", serverId: "t_upper")
        let lower = VoidFixtures.template("Lower", serverId: "t_lower")
        let program = VoidFixtures.program(
            workouts: [
                VoidFixtures.programWorkout(day: 0, label: "Upper", template: upper),
                VoidFixtures.programWorkout(day: 1, label: "Lower", template: lower),
                VoidFixtures.programWorkout(day: 2, label: "Upper", template: upper),
            ],
            currentDayIndex: 1
        )
        let skip = VoidFixtures.skip(program.workouts[0], program: program, on: VoidFixtures.date(2026, 9, 7))

        let rows = PlanRotationBuilder.rows(
            for: program,
            completedWorkouts: [],
            skippedWorkouts: [skip],
            now: now,
            calendar: calendar
        )

        #expect(rows[0].state == .skipped)
        #expect(rows[2].state == .later)
    }

    @Test func aSkipNeverBecomesAStreakOrVolume() {
        // The point of the distinction: a skip writes no TrackedWorkout, so the stats
        // that read completed workouts cannot see it.
        let program = VoidFixtures.pplProgram(currentDayIndex: 1)
        let stats = ProgressStatsCalculator.compute(workouts: [], program: program)
        #expect(stats.streakWeeks == 0)
    }

    // MARK: - Store

    @Test func recordsRemovesAndPersists() {
        let defaults = VoidFixtures.defaults()
        let store = SkippedWorkoutStore(defaults: defaults, userIdProvider: { "u1" })
        let program = VoidFixtures.pplProgram()
        let skip = VoidFixtures.skip(program.workouts[0], program: program)

        store.record(skip)
        #expect(store.skipped.count == 1)

        // A fresh store over the same defaults sees it.
        let reloaded = SkippedWorkoutStore(defaults: defaults, userIdProvider: { "u1" })
        #expect(reloaded.skipped.map(\.id) == [skip.id])

        store.remove(id: skip.id)
        #expect(store.skipped.isEmpty)
        #expect(SkippedWorkoutStore(defaults: defaults, userIdProvider: { "u1" }).skipped.isEmpty)
    }

    @Test func recordingTheSameDayTwiceReplacesRatherThanStacks() {
        let store = SkippedWorkoutStore(defaults: VoidFixtures.defaults(), userIdProvider: { "u1" })
        let program = VoidFixtures.pplProgram()
        let workout = program.workouts[0]

        store.record(VoidFixtures.skip(workout, program: program, on: VoidFixtures.daysAgo(1)))
        store.record(VoidFixtures.skip(workout, program: program, on: VoidFixtures.now))

        #expect(store.skipped.count == 1)
    }

    @Test func clearingAPlanLeavesOtherPlansAlone() {
        let store = SkippedWorkoutStore(defaults: VoidFixtures.defaults(), userIdProvider: { "u1" })
        let program = VoidFixtures.pplProgram()
        store.record(VoidFixtures.skip(program.workouts[0], program: program))
        store.record(SkippedWorkout(
            programServerId: "prog_other",
            workoutId: UUID(),
            templateServerId: "t_other",
            date: VoidFixtures.now
        ))

        store.clear(programServerId: program.serverId)
        #expect(store.skipped.map(\.programServerId) == ["prog_other"])
    }

    @Test func skipsOutsideTheRetentionWindowArePruned() {
        let defaults = VoidFixtures.defaults()
        let store = SkippedWorkoutStore(defaults: defaults, userIdProvider: { "u1" })
        let program = VoidFixtures.pplProgram()

        store.record(VoidFixtures.skip(program.workouts[0], program: program, on: VoidFixtures.daysAgo(400)))
        store.refresh(now: VoidFixtures.now)

        #expect(store.skipped.isEmpty)
    }

    @Test func skipsAreScopedToTheSignedInUser() {
        let defaults = VoidFixtures.defaults()
        let program = VoidFixtures.pplProgram()
        let mine = SkippedWorkoutStore(defaults: defaults, userIdProvider: { "u1" })
        mine.record(VoidFixtures.skip(program.workouts[0], program: program))

        let theirs = SkippedWorkoutStore(defaults: defaults, userIdProvider: { "u2" })
        #expect(theirs.skipped.isEmpty)
    }
}
