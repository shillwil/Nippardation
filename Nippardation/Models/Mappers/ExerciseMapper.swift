//
//  ExerciseMapper.swift
//  Nippardation
//
//  Phase 0: Maps between ExerciseDTO and ExerciseLibraryItem
//

import Foundation

/// Maps between API DTOs and domain models for exercises
enum ExerciseMapper {

    // MARK: - DTO to Domain

    /// Converts an ExerciseDTO to an ExerciseLibraryItem
    static func toDomain(_ dto: ExerciseDTO) -> ExerciseLibraryItem {
        ExerciseLibraryItem(
            id: UUID(),
            serverId: dto.id,
            name: dto.name,
            primaryMuscles: mapMuscleGroups(dto.primaryMuscles),
            secondaryMuscles: mapMuscleGroups(dto.secondaryMuscles ?? []),
            equipment: mapEquipment(dto.equipment),
            difficulty: mapDifficulty(dto.difficulty),
            movementPattern: mapMovementPattern(dto.movementPattern),
            exerciseType: mapExerciseCategory(dto.exerciseType),
            instructions: dto.instructions,
            videoUrl: dto.videoUrl.flatMap { URL(string: $0) },
            thumbnailUrl: dto.thumbnailUrl.flatMap { URL(string: $0) },
            popularityScore: dto.popularityScore ?? 0,
            lastFetchedAt: Date()
        )
    }

    /// Converts multiple ExerciseDTOs to ExerciseLibraryItems
    static func toDomain(_ dtos: [ExerciseDTO]) -> [ExerciseLibraryItem] {
        dtos.map { toDomain($0) }
    }

    // MARK: - Domain to DTO

    /// Converts an ExerciseLibraryItem to an ExerciseDTO (for debugging/testing)
    static func toDTO(_ item: ExerciseLibraryItem) -> ExerciseDTO {
        ExerciseDTO(
            id: item.serverId,
            name: item.name,
            primaryMuscles: item.primaryMuscles.map { $0.rawValue },
            secondaryMuscles: item.secondaryMuscles.isEmpty ? nil : item.secondaryMuscles.map { $0.rawValue },
            equipment: item.equipment?.rawValue,
            difficulty: item.difficulty?.rawValue,
            movementPattern: item.movementPattern?.rawValue,
            exerciseType: item.exerciseType?.rawValue,
            instructions: item.instructions,
            videoUrl: item.videoUrl?.absoluteString,
            thumbnailUrl: item.thumbnailUrl?.absoluteString,
            popularityScore: item.popularityScore,
            createdAt: nil,
            updatedAt: nil
        )
    }

    // MARK: - Helper Methods

    /// Maps string muscle names to MuscleGroup enum values
    private static func mapMuscleGroups(_ strings: [String]) -> [MuscleGroup] {
        strings.compactMap { string in
            // Try direct rawValue match first
            if let muscle = MuscleGroup(rawValue: string.lowercased()) {
                return muscle
            }
            // Handle common variations
            switch string.lowercased() {
            case "chest", "pectorals", "pecs":
                return .chest
            case "back", "lats", "latissimus", "upper back", "lower back":
                return .back
            case "shoulders", "delts", "deltoids", "front delts", "rear delts", "side delts":
                return .shoulders
            case "biceps", "bicep":
                return .biceps
            case "triceps", "tricep":
                return .triceps
            case "quads", "quadriceps":
                return .quads
            case "hamstrings", "hamstring", "hams":
                return .hamstrings
            case "glutes", "glute", "gluteus":
                return .glutes
            case "calves", "calf":
                return .calves
            case "abs", "core", "abdominals":
                return .abs
            default:
                return nil
            }
        }
    }

    /// Maps string to Equipment enum
    private static func mapEquipment(_ string: String?) -> Equipment? {
        guard let string = string else { return nil }
        if let equipment = Equipment(rawValue: string.lowercased()) {
            return equipment
        }
        // Handle common variations
        switch string.lowercased() {
        case "barbell", "bb":
            return .barbell
        case "dumbbell", "dumbbells", "db":
            return .dumbbell
        case "cable", "cables":
            return .cable
        case "machine", "machines":
            return .machine
        case "bodyweight", "body weight", "bw":
            return .bodyweight
        case "kettlebell", "kb":
            return .kettlebell
        case "resistance band", "band", "bands":
            return .resistanceBand
        case "smith machine", "smith":
            return .smithMachine
        case "ez bar", "ez-bar", "curl bar":
            return .ezBar
        case "trap bar", "hex bar":
            return .trapBar
        case "pull-up bar", "pullup bar", "chin up bar":
            return .pullupBar
        case "bench":
            return .bench
        default:
            return .other
        }
    }

    /// Maps string to Difficulty enum
    private static func mapDifficulty(_ string: String?) -> Difficulty? {
        guard let string = string else { return nil }
        return Difficulty(rawValue: string.lowercased())
    }

    /// Maps string to MovementPattern enum
    private static func mapMovementPattern(_ string: String?) -> MovementPattern? {
        guard let string = string else { return nil }
        return MovementPattern(rawValue: string.lowercased())
    }

    /// Maps string to ExerciseCategory enum
    private static func mapExerciseCategory(_ string: String?) -> ExerciseCategory? {
        guard let string = string else { return nil }
        return ExerciseCategory(rawValue: string.lowercased())
    }
}
