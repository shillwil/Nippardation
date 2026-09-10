//
//  SkippedWorkout.swift
//  Nippardation
//
//  A plan day the user chose not to do. Skip Workout advances the plan past the scheduled
//  workout without logging anything, and records one of these so the rotation can read
//  SKIPPED instead of falling back to DONE (it wasn't) or LATER (it isn't coming).
//
//  Nothing here reaches the streak, volume or PR history: a skip is the absence of a
//  workout, not a workout with no sets in it.
//

import Foundation

struct SkippedWorkout: Codable, Equatable, Identifiable {
    var id: UUID
    /// The plan the skipped day belongs to.
    let programServerId: String
    /// `ProgramWorkout.id` of the day that was skipped — the primary match.
    let workoutId: UUID
    /// The template behind that day. The fallback match for when the plan is edited
    /// and the workout rows are rebuilt with new ids.
    let templateServerId: String
    /// When it was skipped.
    let date: Date

    init(
        id: UUID = UUID(),
        programServerId: String,
        workoutId: UUID,
        templateServerId: String,
        date: Date = Date()
    ) {
        self.id = id
        self.programServerId = programServerId
        self.workoutId = workoutId
        self.templateServerId = templateServerId
        self.date = date
    }

    /// True when this skip is the one that stands for `workout` in the rotation.
    func matches(_ workout: ProgramWorkout) -> Bool {
        if workoutId == workout.id { return true }
        return !templateServerId.isEmpty && templateServerId == workout.templateServerId
    }
}
