//
//  TemplateExercise.swift
//  Nippardation
//
//  Phase 0: Domain model for exercises within templates
//

import Foundation

/// Domain model representing an exercise within a template
/// Contains the exercise configuration (sets, reps, rest) for the template
struct TemplateExercise: Identifiable, Hashable {
    let id: UUID
    let serverId: String

    /// The server ID of the exercise from the library
    let exerciseServerId: String

    /// The resolved exercise library item (may be nil if not yet fetched)
    var exerciseLibraryItem: ExerciseLibraryItem?

    /// Order of this exercise within the template
    var orderIndex: Int

    /// Number of warmup sets
    var warmupSets: Int?

    /// Number of working sets
    var workingSets: Int

    /// Target rep range (e.g., "8-12", "5", "10-15")
    var targetReps: String?

    /// Rest period in seconds between sets
    var restSeconds: Int?

    /// Additional notes or instructions
    var notes: String?

    // MARK: - Computed Properties

    /// Display name from the library item or a placeholder
    var displayName: String {
        exerciseLibraryItem?.name ?? "Unknown Exercise"
    }

    /// Formatted rest time string
    var formattedRestTime: String {
        guard let rest = restSeconds else { return "No rest specified" }
        if rest >= 60 {
            let minutes = rest / 60
            let seconds = rest % 60
            if seconds == 0 {
                return "\(minutes) min"
            }
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "\(rest) sec"
    }

    /// Summary string for display (e.g., "3x8-12")
    var setSummary: String {
        let reps = targetReps ?? "?"
        return "\(workingSets)x\(reps)"
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TemplateExercise, rhs: TemplateExercise) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Convenience Initializers

extension TemplateExercise {
    /// Creates a new template exercise from a library item
    static func from(
        libraryItem: ExerciseLibraryItem,
        orderIndex: Int,
        workingSets: Int = 3,
        warmupSets: Int? = nil,
        targetReps: String? = "8-12",
        restSeconds: Int? = 90
    ) -> TemplateExercise {
        TemplateExercise(
            id: UUID(),
            serverId: "",
            exerciseServerId: libraryItem.serverId,
            exerciseLibraryItem: libraryItem,
            orderIndex: orderIndex,
            warmupSets: warmupSets,
            workingSets: workingSets,
            targetReps: targetReps,
            restSeconds: restSeconds,
            notes: nil
        )
    }
}
