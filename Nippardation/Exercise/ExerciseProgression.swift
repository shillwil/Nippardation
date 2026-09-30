//
//  ExerciseProgression.swift
//  Nippardation
//
//  Pure rules behind the logging sheet's Complete exercise flow: which exercise comes next,
//  and which of the two bottom buttons leads.
//

import Foundation

enum ExerciseProgression {
    /// The exercise to open after `current` is completed: the next one in plan order that
    /// isn't completed, wrapping to the top so one skipped earlier (a busy machine) comes up
    /// last. Never returns `current`; nil means everything else is done.
    static func nextUnfinishedIndex(after current: Int, in exercises: [TrackedExercise]) -> Int? {
        guard !exercises.isEmpty else { return nil }
        guard exercises.indices.contains(current) else {
            return exercises.firstIndex { !$0.isCompleted }
        }
        for step in 1..<exercises.count {
            let index = (current + step) % exercises.count
            if !exercises[index].isCompleted {
                return index
            }
        }
        return nil
    }
}

/// The logging sheet's bottom buttons: Add set and Complete exercise. Exactly one leads at a
/// time (HIG: one primary action) — Add set until the target sets are in, then Complete.
struct ExerciseCTAState: Equatable {
    let canAddSet: Bool
    let canComplete: Bool
    let completeIsPrimary: Bool

    var addSetIsPrimary: Bool {
        canAddSet && !completeIsPrimary
    }

    init(loggedSets: Int, targetSets: Int, hasExercise: Bool) {
        canAddSet = hasExercise
        canComplete = hasExercise && loggedSets > 0
        completeIsPrimary = canComplete && loggedSets >= max(targetSets, 1)
    }
}
