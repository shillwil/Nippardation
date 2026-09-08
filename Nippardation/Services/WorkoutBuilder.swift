//
//  WorkoutBuilder.swift
//  Nippardation
//
//  Turns a Template (server model) into the Workout the active-workout logger runs.
//  One implementation shared by Today, Swap Workout and previews.
//

import Foundation

enum WorkoutBuilder {

    /// Builds a runnable workout from a template. `fallbackName` is used when the template has no name.
    static func workout(from template: Template, fallbackName: String? = nil) -> Workout {
        let exercises = template.exercises
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { exercise(from: $0) }

        let trimmed = template.name.trimmingCharacters(in: .whitespaces)
        let name = trimmed.isEmpty ? (fallbackName ?? "Workout") : trimmed
        return Workout(name: name, exercises: exercises)
    }

    static func exercise(from templateExercise: TemplateExercise) -> Exercise {
        let libraryItem = templateExercise.exerciseLibraryItem
        let restMinutes = restMinutes(from: templateExercise.restSeconds)

        return Exercise(
            type: ExerciseType(
                // Prefer any name the app already has (a resolved library item, or the
                // name-only placeholder an AI plan carries) over the generic word.
                name: templateExercise.displayName,
                muscleGroup: libraryItem?.primaryMuscles ?? []
            ),
            exerciseServerId: libraryItem?.serverId ?? templateExercise.exerciseServerId,
            example: libraryItem?.videoUrl?.absoluteString ?? "",
            lastSetIntensityTechnique: templateExercise.notes ?? "Failure",
            warmUpSets: templateExercise.warmupSets ?? 0,
            workingSets: max(1, templateExercise.workingSets),
            reps: repsRange(from: templateExercise.targetReps),
            rest: restMinutes...restMinutes
        )
    }

    /// "8-12" → 8...12, "5" → 5...5, nil → 8...12
    static func repsRange(from targetReps: String?) -> ClosedRange<Int> {
        guard let targetReps, !targetReps.isEmpty else { return 8...12 }
        let values = targetReps.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard let first = values.first else { return 8...12 }
        let lower = max(1, first)
        let upper = values.count > 1 ? max(lower, values[1]) : lower
        return lower...upper
    }

    /// Rest in whole minutes, never below one.
    static func restMinutes(from restSeconds: Int?) -> Int {
        let seconds = max(30, restSeconds ?? 90)
        return max(1, Int((Double(seconds) / 60.0).rounded()))
    }
}
