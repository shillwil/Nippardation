//
//  ProgramWorkout.swift
//  Nippardation
//
//  Phase 0: Domain model for workouts within programs
//

import Foundation

/// Domain model representing a workout day within a program rotation
/// Links a template to a specific day in the program schedule
struct ProgramWorkout: Identifiable, Hashable {
    let id: UUID
    let serverId: String

    /// Day number in the rotation (1-based for display, 0-based internally)
    var dayNumber: Int

    /// Optional label for the day (e.g., "Push Day", "Rest", "Upper Body")
    var dayLabel: String?

    /// The server ID of the template for this workout day
    let templateServerId: String

    /// The resolved template (may be nil if not yet fetched)
    var template: Template?

    // MARK: - Computed Properties

    /// Display name for this workout day
    var displayName: String {
        if let label = dayLabel, !label.isEmpty {
            return label
        }
        if let template = template {
            return template.name
        }
        return "Day \(dayNumber + 1)"
    }

    /// Short day indicator (e.g., "D1", "D2")
    var dayIndicator: String {
        "D\(dayNumber + 1)"
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ProgramWorkout, rhs: ProgramWorkout) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Convenience Initializers

extension ProgramWorkout {
    /// Creates a new program workout from a template
    static func from(
        template: Template,
        dayNumber: Int,
        dayLabel: String? = nil
    ) -> ProgramWorkout {
        ProgramWorkout(
            id: UUID(),
            serverId: "",
            dayNumber: dayNumber,
            dayLabel: dayLabel,
            templateServerId: template.serverId,
            template: template
        )
    }
}
