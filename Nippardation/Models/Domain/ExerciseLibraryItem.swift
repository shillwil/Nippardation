//
//  ExerciseLibraryItem.swift
//  Nippardation
//
//  Phase 0: Domain model for exercise library items
//

import Foundation

/// Domain model representing an exercise from the library
/// Used throughout the app for exercise selection and display
struct ExerciseLibraryItem: Identifiable, Hashable {
    let id: UUID
    let serverId: String
    let name: String
    let primaryMuscles: [MuscleGroup]
    let secondaryMuscles: [MuscleGroup]
    let equipment: Equipment?
    let difficulty: Difficulty?
    let movementPattern: MovementPattern?
    let exerciseType: ExerciseCategory?
    let instructions: String?
    let videoUrl: URL?
    let thumbnailUrl: URL?
    let popularityScore: Int
    let lastFetchedAt: Date?

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ExerciseLibraryItem, rhs: ExerciseLibraryItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Supporting Enums

/// Equipment types for exercises
enum Equipment: String, Codable, CaseIterable {
    case barbell
    case dumbbell
    case cable
    case machine
    case bodyweight
    case kettlebell
    case resistanceBand = "resistance_band"
    case smithMachine = "smith_machine"
    case ezBar = "ez_bar"
    case trapBar = "trap_bar"
    case pullupBar = "pullup_bar"
    case bench
    case other

    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .cable: return "Cable"
        case .machine: return "Machine"
        case .bodyweight: return "Bodyweight"
        case .kettlebell: return "Kettlebell"
        case .resistanceBand: return "Resistance Band"
        case .smithMachine: return "Smith Machine"
        case .ezBar: return "EZ Bar"
        case .trapBar: return "Trap Bar"
        case .pullupBar: return "Pull-up Bar"
        case .bench: return "Bench"
        case .other: return "Other"
        }
    }
}

/// Difficulty levels for exercises
enum Difficulty: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

/// Movement patterns for categorizing exercises
enum MovementPattern: String, Codable, CaseIterable {
    case push
    case pull
    case squat
    case hinge
    case lunge
    case carry
    case rotation
    case isolation

    var displayName: String {
        switch self {
        case .push: return "Push"
        case .pull: return "Pull"
        case .squat: return "Squat"
        case .hinge: return "Hinge"
        case .lunge: return "Lunge"
        case .carry: return "Carry"
        case .rotation: return "Rotation"
        case .isolation: return "Isolation"
        }
    }
}

/// Exercise categories (compound vs isolation, etc.)
enum ExerciseCategory: String, Codable, CaseIterable {
    case compound
    case isolation
    case cardio
    case plyometric
    case stretching

    var displayName: String {
        switch self {
        case .compound: return "Compound"
        case .isolation: return "Isolation"
        case .cardio: return "Cardio"
        case .plyometric: return "Plyometric"
        case .stretching: return "Stretching"
        }
    }
}

// MARK: - Filter Options

/// Filter criteria for browsing exercises
struct ExerciseFilter {
    var searchText: String = ""
    var muscleGroups: Set<MuscleGroup> = []
    var equipment: Set<Equipment> = []
    var difficulty: Difficulty?
    var movementPattern: MovementPattern?
    var exerciseType: ExerciseCategory?

    var isEmpty: Bool {
        searchText.isEmpty &&
        muscleGroups.isEmpty &&
        equipment.isEmpty &&
        difficulty == nil &&
        movementPattern == nil &&
        exerciseType == nil
    }

    mutating func reset() {
        searchText = ""
        muscleGroups = []
        equipment = []
        difficulty = nil
        movementPattern = nil
        exerciseType = nil
    }
}
