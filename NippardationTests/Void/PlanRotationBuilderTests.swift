//
//  PlanRotationBuilderTests.swift
//  NippardationTests
//

import Testing
import Foundation
@testable import Nippardation

@Suite("PlanRotationBuilder")
struct PlanRotationBuilderTests {

    private let calendar = VoidFixtures.calendar
    private let now = VoidFixtures.now // Wed 2026-09-09

    @Test func marksNextDoneAndLater() {
        let program = VoidFixtures.pplProgram(currentDayIndex: 1)
        let completedPush = VoidFixtures.workout(name: "Push", on: VoidFixtures.date(2026, 9, 7))
        let rows = PlanRotationBuilder.rows(for: program, completedWorkouts: [completedPush], now: now, calendar: calendar)

        #expect(rows.count == 3)
        #expect(rows[0].state == .done)
        #expect(rows[0].weekday == "MON")         // actual completion date
        #expect(rows[1].state == .next)
        #expect(rows[1].weekday == "WED")         // today
        #expect(rows[2].state == .later)
        #expect(rows[2].weekday == "THU")         // projected tomorrow
    }

    @Test func rowsAboveTheIndexProjectOntoThePrecedingDaysWhenNotDone() {
        let program = VoidFixtures.pplProgram(currentDayIndex: 2)
        let rows = PlanRotationBuilder.rows(for: program, completedWorkouts: [], now: now, calendar: calendar)
        #expect(rows[2].state == .next)
        #expect(rows[2].weekday == "WED")
        #expect(rows[0].state == .later)
        #expect(rows[0].weekday == "MON")         // today − 2, no DONE label
        #expect(rows[1].weekday == "TUE")
    }

    @Test func lastWeeksCompletionDoesNotCountAsDone() {
        let program = VoidFixtures.pplProgram(currentDayIndex: 1)
        let lastWeek = VoidFixtures.workout(name: "Push", on: VoidFixtures.date(2026, 9, 5))
        let rows = PlanRotationBuilder.rows(for: program, completedWorkouts: [lastWeek], now: now, calendar: calendar)
        #expect(rows[0].state == .later)
    }

    @Test func eyebrowAndWordVocabulary() {
        let program = VoidFixtures.pplProgram(currentDayIndex: 1)
        let completedPush = VoidFixtures.workout(name: "Push", on: VoidFixtures.date(2026, 9, 7))
        let rows = PlanRotationBuilder.rows(for: program, completedWorkouts: [completedPush], now: now, calendar: calendar)
        #expect(rows[0].eyebrow == "MON · DONE")
        #expect(rows[1].eyebrow == "▮ WED · UP NEXT")
        #expect(rows[2].eyebrow == "THU")
        #expect(rows[1].word == "Pull")
        #expect(rows[1].glyph == .workoutPull)
        #expect(rows[2].glyph == .workoutLegs)
    }

    @Test func wordFallsBackToLabelThenDayNumber() {
        let unresolved = VoidFixtures.programWorkout(day: 0, label: nil, template: nil)
        let labelled = VoidFixtures.programWorkout(day: 1, label: "Arms", template: nil)
        let program = VoidFixtures.program(workouts: [unresolved, labelled], daysPerWeek: 2)
        let rows = PlanRotationBuilder.rows(for: program, now: now, calendar: calendar)
        #expect(rows[0].word == "DAY 01")
        #expect(rows[1].word == "Arms")
        #expect(rows[1].glyph == .workoutUpper)
    }

    @Test func resolvesTemplatesFromTheProvidedList() {
        let bare = VoidFixtures.programWorkout(day: 0, label: nil, template: nil)
        let program = VoidFixtures.program(workouts: [bare], daysPerWeek: 1)
        let resolved = VoidFixtures.template("Legs", serverId: bare.templateServerId)
        let rows = PlanRotationBuilder.rows(for: program, templates: [resolved], now: now, calendar: calendar)
        #expect(rows[0].word == "Legs")
        #expect(rows[0].template?.serverId == bare.templateServerId)
    }

    @Test func outOfRangeIndexIsWrapped() {
        let program = VoidFixtures.pplProgram(currentDayIndex: 4)
        let rows = PlanRotationBuilder.rows(for: program, now: now, calendar: calendar)
        #expect(rows[1].state == .next)
    }

    @Test func emptyProgramHasNoRows() {
        let program = VoidFixtures.program(workouts: [], daysPerWeek: 3)
        #expect(PlanRotationBuilder.rows(for: program, now: now, calendar: calendar).isEmpty)
    }
}
