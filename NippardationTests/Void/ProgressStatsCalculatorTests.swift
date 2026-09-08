//
//  ProgressStatsCalculatorTests.swift
//  NippardationTests
//

import Testing
import Foundation
@testable import Nippardation

@Suite("ProgressStatsCalculator")
struct ProgressStatsCalculatorTests {

    private let calendar = VoidFixtures.calendar
    private let now = VoidFixtures.now // Wed 2026-09-09; week = Mon 09-07 … Sun 09-13

    @Test func countsOnlyThisWeeksWorkouts() {
        let workouts = [
            VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 7)),   // Mon this week
            VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 8)),   // Tue this week
            VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 6)),   // Sun last week
            VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 10), completed: false),
        ]
        let stats = ProgressStatsCalculator.compute(workouts: workouts, program: nil, now: now, calendar: calendar)
        #expect(stats.doneThisWeek == 2)
        #expect(stats.plannedThisWeek == nil)
    }

    @Test func plannedThisWeekComesFromThePlan() {
        let stats = ProgressStatsCalculator.compute(workouts: [], program: VoidFixtures.pplProgram(), now: now, calendar: calendar)
        #expect(stats.plannedThisWeek == 3)
    }

    @Test func volumeExcludesWarmupsAndComparesToLastWeek() {
        let thisWeek = VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 8), exercises: [
            VoidFixtures.exercise("Bench Press", sets: [
                VoidFixtures.set(10, 45, .warmup),
                VoidFixtures.set(10, 100),
                VoidFixtures.set(8, 110),
            ]),
        ])
        let lastWeek = VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 2), exercises: [
            VoidFixtures.exercise("Bench Press", sets: [VoidFixtures.set(10, 100)]),
        ])
        let stats = ProgressStatsCalculator.compute(workouts: [thisWeek, lastWeek], program: nil, now: now, calendar: calendar)
        #expect(stats.volumeThisWeek == 1000 + 880)
        #expect(stats.volumeLastWeek == 1000)
        #expect(stats.volumeDeltaPercent == 88)
    }

    @Test func volumeDeltaIsNilWithoutLastWeek() {
        let thisWeek = VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 8), exercises: [
            VoidFixtures.exercise("Bench Press", sets: [VoidFixtures.set(10, 100)]),
        ])
        let stats = ProgressStatsCalculator.compute(workouts: [thisWeek], program: nil, now: now, calendar: calendar)
        #expect(stats.volumeDeltaPercent == nil)
    }

    @Test func personalRecordsNeedPriorHistory() {
        let history = VoidFixtures.workout(on: VoidFixtures.date(2026, 8, 20), exercises: [
            VoidFixtures.exercise("Bench Press", sets: [VoidFixtures.set(5, 200)]),
            VoidFixtures.exercise("Squat", sets: [VoidFixtures.set(5, 300)]),
        ])
        let thisWeek = VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 8), exercises: [
            VoidFixtures.exercise("Bench Press", sets: [VoidFixtures.set(5, 205)]),   // PR
            VoidFixtures.exercise("Squat", sets: [VoidFixtures.set(5, 295)]),         // not a PR
            VoidFixtures.exercise("Deadlift", sets: [VoidFixtures.set(5, 400)]),      // first time, not counted
        ])
        let stats = ProgressStatsCalculator.compute(workouts: [history, thisWeek], program: nil, now: now, calendar: calendar)
        #expect(stats.prsThisWeek == 1)
    }

    @Test func estimatedOneRepMaxUsesEpley() {
        #expect(ProgressStatsCalculator.estimatedOneRepMax(weight: 100, reps: 1) == 100)
        #expect(ProgressStatsCalculator.estimatedOneRepMax(weight: 100, reps: 10) == 100 * (1 + 10.0 / 30))
        #expect(ProgressStatsCalculator.estimatedOneRepMax(weight: 0, reps: 10) == 0)
    }

    @Test func streakCountsConsecutiveWeeks() {
        let workouts = [
            VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 8)),   // this week
            VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 1)),   // last week
            VoidFixtures.workout(on: VoidFixtures.date(2026, 8, 25)),  // two weeks ago
            VoidFixtures.workout(on: VoidFixtures.date(2026, 8, 10)),  // gap → four weeks ago, not counted
        ]
        let stats = ProgressStatsCalculator.compute(workouts: workouts, program: nil, now: now, calendar: calendar)
        #expect(stats.streakWeeks == 3)
    }

    @Test func emptyCurrentWeekDoesNotBreakTheStreak() {
        let workouts = [
            VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 1)),   // last week
            VoidFixtures.workout(on: VoidFixtures.date(2026, 8, 25)),  // two weeks ago
        ]
        let stats = ProgressStatsCalculator.compute(workouts: workouts, program: nil, now: now, calendar: calendar)
        #expect(stats.streakWeeks == 2)
    }

    @Test func streakIsZeroAfterAMissedWeek() {
        let workouts = [VoidFixtures.workout(on: VoidFixtures.date(2026, 8, 25))]
        let stats = ProgressStatsCalculator.compute(workouts: workouts, program: nil, now: now, calendar: calendar)
        #expect(stats.streakWeeks == 0)
    }

    @Test func weeklyChartHasEightBucketsOldestFirst() {
        let workouts = [
            VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 8)),
            VoidFixtures.workout(on: VoidFixtures.date(2026, 9, 7)),
            VoidFixtures.workout(on: VoidFixtures.date(2026, 7, 22)), // 7 weeks ago → first bucket
            VoidFixtures.workout(on: VoidFixtures.date(2026, 7, 15)), // 8 weeks ago → outside
        ]
        let stats = ProgressStatsCalculator.compute(workouts: workouts, program: VoidFixtures.pplProgram(), now: now, calendar: calendar)
        #expect(stats.weeklyCounts.count == 8)
        #expect(stats.weeklyCounts.first == 1)
        #expect(stats.weeklyCounts.last == 2)
        #expect(stats.weeklyRatios.last == 2.0 / 3.0)
        #expect(stats.weeklyRatios.allSatisfy { $0 >= 0 && $0 <= 1 })
    }

    @Test func planProgressCountsCyclesAndIndex() {
        let program = VoidFixtures.pplProgram(currentDayIndex: 2, timesCompleted: 3, durationWeeks: 8)
        let stats = ProgressStatsCalculator.compute(workouts: [], program: program, now: now, calendar: calendar)
        #expect(stats.planCompletedWorkouts == 11)   // 3 × 3 + 2
        #expect(stats.planTotalWorkouts == 24)       // 8 × 3
        #expect(stats.planCurrentWeek == 4)          // 11 / 3 + 1
        #expect(stats.planTotalWeeks == 8)
        #expect(stats.planProgress == 11.0 / 24.0)
    }

    @Test func indefinitePlanHasNoTotals() {
        let program = VoidFixtures.pplProgram(currentDayIndex: 1, timesCompleted: 1, durationWeeks: nil)
        let stats = ProgressStatsCalculator.compute(workouts: [], program: program, now: now, calendar: calendar)
        #expect(stats.planCompletedWorkouts == 4)
        #expect(stats.planTotalWorkouts == nil)
        #expect(stats.planTotalWeeks == nil)
        #expect(stats.planProgress == nil)
        #expect(stats.planCurrentWeek == 2)
    }
}
