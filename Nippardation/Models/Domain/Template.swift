//
//  Template.swift
//  Nippardation
//
//  Phase 0: Domain model for workout templates
//

import Foundation

/// Domain model representing a workout template
/// Templates define a workout structure that can be used to start workouts
struct Template: Identifiable, Hashable {
    let id: UUID
    let serverId: String
    var name: String
    var description: String?
    var exercises: [TemplateExercise]
    var isPublic: Bool
    var isAiGenerated: Bool
    let createdAt: Date
    var updatedAt: Date
    var lastFetchedAt: Date?

    // MARK: - Computed Properties

    /// Number of exercises in the template
    var exerciseCount: Int {
        exercises.isEmpty ? (_knownExerciseCount ?? 0) : exercises.count
    }

    /// Stored exercise count from API (used when exercises array is empty but count is known from list endpoint)
    var _knownExerciseCount: Int? = nil

    /// Total number of working sets in the template
    var totalWorkingSets: Int {
        exercises.reduce(0) { $0 + $1.workingSets }
    }

    /// Total number of warmup sets in the template
    var totalWarmupSets: Int {
        exercises.reduce(0) { $0 + ($1.warmupSets ?? 0) }
    }

    /// Estimated duration in minutes (rough estimate based on sets and rest)
    var estimatedDurationMinutes: Int {
        let totalSets = totalWorkingSets + totalWarmupSets
        let restValues = exercises.compactMap { $0.restSeconds }
        let averageRestSeconds = restValues.isEmpty ? 0 : restValues.reduce(0, +) / restValues.count
        let setDuration = 45 // Average seconds per set
        let totalSeconds = totalSets * (setDuration + (averageRestSeconds > 0 ? averageRestSeconds : 90))
        return totalSeconds / 60
    }

    /// All unique muscle groups targeted by this template
    var targetedMuscleGroups: Set<MuscleGroup> {
        var muscles = Set<MuscleGroup>()
        for exercise in exercises {
            if let libraryItem = exercise.exerciseLibraryItem {
                muscles.formUnion(libraryItem.primaryMuscles)
            }
        }
        return muscles
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Template, rhs: Template) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Convenience Initializers

extension Template {
    /// Creates a new empty template
    static func empty(name: String = "New Template") -> Template {
        Template(
            id: UUID(),
            serverId: "",
            name: name,
            description: nil,
            exercises: [],
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
    }
}
