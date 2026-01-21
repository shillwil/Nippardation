//
//  Program.swift
//  Nippardation
//
//  Phase 0: Domain model for workout programs
//

import Foundation

/// Domain model representing a workout program
/// Programs define a rotation of templates (workouts) for structured training
struct Program: Identifiable, Hashable {
    let id: UUID
    let serverId: String
    var name: String
    var description: String?
    var daysPerWeek: Int
    var durationWeeks: Int?
    var workouts: [ProgramWorkout]
    var isActive: Bool
    var currentDayIndex: Int
    var timesCompleted: Int
    var isPublic: Bool
    var isAiGenerated: Bool
    let createdAt: Date
    var updatedAt: Date
    var lastFetchedAt: Date?

    // MARK: - Computed Properties

    /// The workout scheduled for the current day
    var currentWorkout: ProgramWorkout? {
        guard currentDayIndex >= 0 && currentDayIndex < workouts.count else { return nil }
        return workouts.sorted(by: { $0.dayNumber < $1.dayNumber })[currentDayIndex]
    }

    /// The next workout in the rotation
    var nextWorkout: ProgramWorkout? {
        guard !workouts.isEmpty else { return nil }
        let sortedWorkouts = workouts.sorted(by: { $0.dayNumber < $1.dayNumber })
        let nextIndex = (currentDayIndex + 1) % sortedWorkouts.count
        return sortedWorkouts[nextIndex]
    }

    /// Whether this is an indefinite (ongoing) program
    var isIndefinite: Bool {
        durationWeeks == nil || durationWeeks == 0
    }

    /// Progress percentage (0-1) based on duration
    var progress: Double {
        guard let weeks = durationWeeks, weeks > 0 else { return 0 }
        let completedDays = timesCompleted * workouts.count + currentDayIndex
        let totalDays = weeks * daysPerWeek
        return min(1.0, Double(completedDays) / Double(totalDays))
    }

    /// Human-readable duration string
    var durationString: String {
        guard let weeks = durationWeeks, weeks > 0 else { return "Ongoing" }
        return weeks == 1 ? "1 week" : "\(weeks) weeks"
    }

    /// Human-readable frequency string
    var frequencyString: String {
        return daysPerWeek == 1 ? "1 day/week" : "\(daysPerWeek) days/week"
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Program, rhs: Program) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Mutations

    /// Advances to the next workout in the rotation
    mutating func advanceToNextWorkout() {
        currentDayIndex = (currentDayIndex + 1) % max(workouts.count, 1)
        if currentDayIndex == 0 {
            timesCompleted += 1
        }
        updatedAt = Date()
    }
}

// MARK: - Convenience Initializers

extension Program {
    /// Creates a new empty program
    static func empty(name: String = "New Program") -> Program {
        Program(
            id: UUID(),
            serverId: "",
            name: name,
            description: nil,
            daysPerWeek: 3,
            durationWeeks: nil,
            workouts: [],
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
    }
}
