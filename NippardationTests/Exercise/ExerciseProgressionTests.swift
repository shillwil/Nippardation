//
//  ExerciseProgressionTests.swift
//  NippardationTests
//
//  Complete exercise: which exercise opens next, and which bottom button leads.
//

import Testing
import Foundation
@testable import Nippardation

@Suite("Exercise progression")
struct ExerciseProgressionTests {

    /// Builds a workout's exercises from a pattern: "d" completed, "p" in progress (sets but
    /// not completed), "o" not started.
    private func exercises(_ pattern: String) -> [TrackedExercise] {
        pattern.enumerated().map { index, state in
            var exercise = VoidFixtures.exercise(
                "Exercise \(index)",
                sets: state == "o" ? [] : [VoidFixtures.set(8, 135)]
            )
            if state == "d" {
                exercise.completedAt = VoidFixtures.now
            }
            return exercise
        }
    }

    // MARK: - Next exercise

    @Test func movesForwardPastTheCurrentExercise() {
        #expect(ExerciseProgression.nextUnfinishedIndex(after: 1, in: exercises("ddoo")) == 2)
    }

    @Test func skipsCompletedExercises() {
        #expect(ExerciseProgression.nextUnfinishedIndex(after: 0, in: exercises("dddo")) == 3)
    }

    @Test func wrapsSoASkippedExerciseComesUpLast() {
        // The first exercise was skipped (machine taken); after the last one, it comes back.
        #expect(ExerciseProgression.nextUnfinishedIndex(after: 2, in: exercises("odd")) == 0)
    }

    @Test func returnsToAPartlyLoggedExercise() {
        // Sets but no Complete: still unfinished.
        #expect(ExerciseProgression.nextUnfinishedIndex(after: 0, in: exercises("dpd")) == 1)
    }

    @Test func returnsNilWhenEverythingElseIsDone() {
        #expect(ExerciseProgression.nextUnfinishedIndex(after: 1, in: exercises("ddd")) == nil)
        #expect(ExerciseProgression.nextUnfinishedIndex(after: 0, in: exercises("d")) == nil)
        #expect(ExerciseProgression.nextUnfinishedIndex(after: 0, in: []) == nil)
    }

    @Test func neverReturnsTheCurrentExercise() {
        #expect(ExerciseProgression.nextUnfinishedIndex(after: 1, in: exercises("dod")) == nil)
        #expect(ExerciseProgression.nextUnfinishedIndex(after: 0, in: exercises("o")) == nil)
    }

    @Test func outOfRangeCurrentFallsBackToTheFirstUnfinished() {
        let list = exercises("dod")
        #expect(ExerciseProgression.nextUnfinishedIndex(after: -1, in: list) == 1)
        #expect(ExerciseProgression.nextUnfinishedIndex(after: 3, in: list) == 1)
    }

    // MARK: - Bottom buttons

    @Test func noSetsLeadsWithAddSetAndDisablesComplete() {
        let cta = ExerciseCTAState(loggedSets: 0, targetSets: 4, hasExercise: true)
        #expect(cta.addSetIsPrimary)
        #expect(cta.canAddSet)
        #expect(cta.canComplete == false)
        #expect(cta.completeIsPrimary == false)
    }

    @Test func belowTargetKeepsAddSetLeadingButAllowsComplete() {
        let cta = ExerciseCTAState(loggedSets: 2, targetSets: 4, hasExercise: true)
        #expect(cta.addSetIsPrimary)
        #expect(cta.canComplete)
        #expect(cta.completeIsPrimary == false)
    }

    @Test func reachingTheTargetHandsTheLeadToComplete() {
        let atTarget = ExerciseCTAState(loggedSets: 4, targetSets: 4, hasExercise: true)
        #expect(atTarget.completeIsPrimary)
        #expect(atTarget.addSetIsPrimary == false)
        #expect(atTarget.canAddSet)

        let pastTarget = ExerciseCTAState(loggedSets: 6, targetSets: 4, hasExercise: true)
        #expect(pastTarget.completeIsPrimary)
    }

    @Test func aZeroTargetNeedsOneSetBeforeCompleteLeads() {
        #expect(ExerciseCTAState(loggedSets: 0, targetSets: 0, hasExercise: true).completeIsPrimary == false)
        #expect(ExerciseCTAState(loggedSets: 1, targetSets: 0, hasExercise: true).completeIsPrimary)
    }

    @Test func withoutAnExerciseNothingIsEnabled() {
        let cta = ExerciseCTAState(loggedSets: 3, targetSets: 3, hasExercise: false)
        #expect(cta.canAddSet == false)
        #expect(cta.canComplete == false)
        #expect(cta.addSetIsPrimary == false)
        #expect(cta.completeIsPrimary == false)
    }

    @Test func atMostOneButtonLeadsAndALeadingButtonIsNeverDisabled() {
        for sets in 0...6 {
            for target in 0...5 {
                for hasExercise in [true, false] {
                    let cta = ExerciseCTAState(loggedSets: sets, targetSets: target, hasExercise: hasExercise)
                    #expect(!(cta.addSetIsPrimary && cta.completeIsPrimary))
                    if cta.addSetIsPrimary { #expect(cta.canAddSet) }
                    if cta.completeIsPrimary { #expect(cta.canComplete) }
                }
            }
        }
    }
}
