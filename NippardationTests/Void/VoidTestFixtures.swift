//
//  VoidTestFixtures.swift
//  NippardationTests
//
//  Deterministic fixtures for the Void stats / rotation / store tests.
//

import Foundation
@testable import Nippardation

enum VoidFixtures {

    /// Gregorian, UTC, weeks start on Monday — matches VoidCalendar but pinned to a time zone.
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 2
        return calendar
    }

    /// Wednesday 2026-09-09 12:00 UTC.
    static var now: Date { date(2026, 9, 9, hour: 12) }

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return calendar.date(from: components)!
    }

    static func daysAgo(_ days: Int, from reference: Date = now) -> Date {
        calendar.date(byAdding: .day, value: -days, to: reference)!
    }

    // MARK: - Tracked workouts

    static func set(_ reps: Int, _ weight: Double, _ type: SetType = .working, name: String = "Bench Press") -> TrackedSet {
        TrackedSet(reps: reps, weight: weight, setType: type, exerciseType: ExerciseType(name: name, muscleGroup: [.chest]))
    }

    static func exercise(_ name: String, sets: [TrackedSet]) -> TrackedExercise {
        TrackedExercise(exerciseName: name, muscleGroups: ["chest"], trackedSets: sets)
    }

    static func workout(
        name: String = "Push",
        on date: Date,
        exercises: [TrackedExercise] = [],
        completed: Bool = true
    ) -> TrackedWorkout {
        TrackedWorkout(date: date, workoutTemplate: name, trackedExercises: exercises, isCompleted: completed)
    }

    // MARK: - Templates & programs

    static func libraryItem(_ name: String, serverId: String = "ex_1") -> ExerciseLibraryItem {
        ExerciseLibraryItem(
            id: UUID(),
            serverId: serverId,
            name: name,
            primaryMuscles: [.chest],
            secondaryMuscles: [],
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .push,
            exerciseType: .compound,
            instructions: nil,
            videoUrl: URL(string: "https://example.com/v.mp4"),
            thumbnailUrl: nil,
            popularityScore: 0,
            lastFetchedAt: nil
        )
    }

    static func templateExercise(
        _ name: String,
        order: Int = 0,
        warmup: Int? = 1,
        working: Int = 3,
        reps: String? = "8-12",
        rest: Int? = 90,
        notes: String? = nil
    ) -> TemplateExercise {
        TemplateExercise(
            id: UUID(),
            serverId: "te_\(order)",
            exerciseServerId: "ex_\(order)",
            exerciseLibraryItem: libraryItem(name, serverId: "ex_\(order)"),
            orderIndex: order,
            warmupSets: warmup,
            workingSets: working,
            targetReps: reps,
            restSeconds: rest,
            notes: notes
        )
    }

    static func template(_ name: String, serverId: String, exercises: [TemplateExercise] = []) -> Template {
        Template(
            id: UUID(),
            serverId: serverId,
            name: name,
            description: nil,
            exercises: exercises,
            isPublic: false,
            isAiGenerated: false,
            createdAt: now,
            updatedAt: now,
            lastFetchedAt: nil
        )
    }

    static func programWorkout(day: Int, label: String?, template: Template?) -> ProgramWorkout {
        ProgramWorkout(
            id: UUID(),
            serverId: "pw_\(day)",
            dayNumber: day,
            dayLabel: label,
            templateServerId: template?.serverId ?? "missing_\(day)",
            template: template
        )
    }

    static func program(
        name: String = "The OG",
        workouts: [ProgramWorkout],
        daysPerWeek: Int? = nil,
        durationWeeks: Int? = 8,
        currentDayIndex: Int = 0,
        timesCompleted: Int = 0,
        isActive: Bool = true
    ) -> Program {
        Program(
            id: UUID(),
            serverId: "prog_test",
            name: name,
            description: nil,
            daysPerWeek: daysPerWeek ?? workouts.count,
            durationWeeks: durationWeeks,
            workouts: workouts,
            isActive: isActive,
            currentDayIndex: currentDayIndex,
            timesCompleted: timesCompleted,
            isPublic: false,
            isAiGenerated: false,
            createdAt: now,
            updatedAt: now,
            lastFetchedAt: nil
        )
    }

    /// Push / Pull / Legs rotation with resolved templates.
    static func pplProgram(currentDayIndex: Int = 1, timesCompleted: Int = 0, durationWeeks: Int? = 8) -> Program {
        let push = template("Push", serverId: "t_push", exercises: [templateExercise("Bench Press", order: 0)])
        let pull = template("Pull", serverId: "t_pull", exercises: [templateExercise("Row", order: 0)])
        let legs = template("Legs", serverId: "t_legs", exercises: [templateExercise("Squat", order: 0)])
        return program(
            workouts: [
                programWorkout(day: 0, label: "Push", template: push),
                programWorkout(day: 1, label: "Pull", template: pull),
                programWorkout(day: 2, label: "Legs", template: legs),
            ],
            daysPerWeek: 3,
            durationWeeks: durationWeeks,
            currentDayIndex: currentDayIndex,
            timesCompleted: timesCompleted
        )
    }

    // MARK: - Isolated UserDefaults

    static func defaults() -> UserDefaults {
        let suite = "void.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
