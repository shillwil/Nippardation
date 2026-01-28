//
//  MockData.swift
//  Nippardation
//
//  Preview data helper for SwiftUI previews
//

import Foundation

/// Provides convenient access to sample data for SwiftUI previews
/// Uses data from mock repository implementations
enum MockData {

    // MARK: - Programs

    /// Sample programs for previews
    @MainActor
    static var programs: [Program] {
        MockProgramRepository.samplePrograms
    }

    /// The first sample program (active, PPL split)
    @MainActor
    static var activeProgram: Program {
        programs.first { $0.isActive } ?? programs[0]
    }

    /// An inactive sample program
    @MainActor
    static var inactiveProgram: Program {
        programs.first { !$0.isActive } ?? programs[0]
    }

    // MARK: - Templates

    /// Sample templates for previews
    @MainActor
    static var templates: [Template] {
        MockTemplateRepository.sampleTemplates
    }

    /// Push day template
    @MainActor
    static var pushTemplate: Template {
        templates.first { $0.name == "Push Day" } ?? templates[0]
    }

    /// Pull day template
    @MainActor
    static var pullTemplate: Template {
        templates.first { $0.name == "Pull Day" } ?? templates[0]
    }

    /// Leg day template
    @MainActor
    static var legTemplate: Template {
        templates.first { $0.name == "Leg Day" } ?? templates[0]
    }

    // MARK: - Exercises

    /// Sample exercises for previews
    @MainActor
    static var exercises: [ExerciseLibraryItem] {
        MockExerciseRepository.sampleExercises
    }

    /// Bench press exercise
    @MainActor
    static var benchPress: ExerciseLibraryItem {
        exercises.first { $0.name.contains("Bench Press") } ?? exercises[0]
    }

    /// Squat exercise
    @MainActor
    static var squat: ExerciseLibraryItem {
        exercises.first { $0.name.contains("Squat") } ?? exercises[0]
    }

    /// Deadlift exercise
    @MainActor
    static var deadlift: ExerciseLibraryItem {
        exercises.first { $0.name.contains("Deadlift") } ?? exercises[0]
    }

    // MARK: - Template Exercises

    /// Sample template exercises for previews
    @MainActor
    static var templateExercises: [TemplateExercise] {
        MockTemplateRepository.samplePushExercises
    }

    // MARK: - Program Workouts

    /// Sample program workouts
    @MainActor
    static var programWorkouts: [ProgramWorkout] {
        activeProgram.workouts
    }

    /// Next workout from active program
    @MainActor
    static var nextWorkout: ProgramWorkout? {
        activeProgram.nextWorkout
    }

    // MARK: - Filter Options

    /// Sample filter options for exercise browser
    @MainActor
    static var filterOptions: ExerciseFilterOptionsDTO {
        ExerciseFilterOptionsDTO(
            muscleGroups: MuscleGroup.allCases.map { muscle in
                FilterOptionDTO(
                    value: muscle.rawValue,
                    label: muscle.rawValue.capitalized,
                    count: exercises.filter { $0.primaryMuscles.contains(muscle) }.count
                )
            },
            difficulties: Difficulty.allCases.map { difficulty in
                FilterOptionDTO(
                    value: difficulty.rawValue,
                    label: difficulty.displayName,
                    count: exercises.filter { $0.difficulty == difficulty }.count
                )
            },
            equipment: Equipment.allCases.map { equipment in
                FilterOptionDTO(
                    value: equipment.rawValue,
                    label: equipment.displayName,
                    count: exercises.filter { $0.equipment == equipment }.count
                )
            },
            movementPatterns: MovementPattern.allCases.map { pattern in
                FilterOptionDTO(
                    value: pattern.rawValue,
                    label: pattern.displayName,
                    count: exercises.filter { $0.movementPattern == pattern }.count
                )
            },
            exerciseTypes: ExerciseCategory.allCases.map { category in
                FilterOptionDTO(
                    value: category.rawValue,
                    label: category.displayName,
                    count: exercises.filter { $0.exerciseType == category }.count
                )
            }
        )
    }

    // MARK: - Empty States

    /// Empty program for creating new programs
    @MainActor
    static var emptyProgram: Program {
        Program.empty(name: "New Program")
    }

    /// Empty template for creating new templates
    @MainActor
    static var emptyTemplate: Template {
        Template.empty(name: "New Template")
    }
}
