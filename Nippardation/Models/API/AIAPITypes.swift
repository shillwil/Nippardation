//
//  AIAPITypes.swift
//  Nippardation
//
//  Request and response types for AI program generation endpoints
//

import Foundation

// MARK: - Generate Program

/// Request body for POST /api/ai/generate-program
struct GenerateProgramRequest: Codable {
    let inspirationSource: String
    let daysPerWeek: Int
    let sessionDurationMinutes: Int
    let experienceLevel: String
    let goal: String
    let equipment: [String]
    let useTrainingHistory: Bool
    let manualStrengthData: [StrengthDataEntry]?
    let freeTextPreferences: String?
    let reuseTemplateIds: [String]?
}

/// Individual strength data entry used in generation requests and strength profiles
struct StrengthDataEntry: Codable, Identifiable {
    var id = UUID()
    var exerciseName: String
    var weight: Double
    var unit: String
    var reps: Int
    var sets: Int

    enum CodingKeys: String, CodingKey {
        case exerciseName, weight, unit, reps, sets
    }
}

/// Response from POST /api/ai/generate-program
/// Uses AI-specific DTOs since the AI endpoint returns a different structure
/// than the regular CRUD program endpoints (no workout IDs, inline templates, etc.)
struct GenerateProgramResponse: Codable {
    let program: AIGeneratedProgramDTO
    let generation: GenerationMetadataDTO
}

/// AI-generated program structure (different from regular ProgramDTO)
struct AIGeneratedProgramDTO: Codable {
    let id: String
    let name: String
    let description: String?
    let daysPerWeek: Int
    let durationWeeks: Int?
    let isAiGenerated: Bool?
    let aiPrompt: String?
    let workouts: [AIGeneratedWorkoutDTO]?
    let createdAt: String?
    let updatedAt: String?
}

/// AI-generated workout (no id/templateId — template is inline)
struct AIGeneratedWorkoutDTO: Codable {
    let dayNumber: Int
    let dayLabel: String?
    let template: AIGeneratedTemplateDTO?
}

/// AI-generated template (includes exerciseCount, different exercise structure)
struct AIGeneratedTemplateDTO: Codable {
    let id: String?
    let name: String?
    let description: String?
    let exerciseCount: Int?
    let wasReused: Bool?
    let exercises: [AIGeneratedExerciseDTO]?
}

/// AI-generated exercise (no id/orderIndex, has name directly)
struct AIGeneratedExerciseDTO: Codable {
    let exerciseId: String?
    let name: String?
    let warmupSets: Int?
    let workingSets: Int?
    let targetReps: String?
    let restSeconds: Int?
    let notes: String?
}

/// Metadata about the AI generation process
struct GenerationMetadataDTO: Codable {
    let timeMs: Int?
    let model: String?
    let personalizationApplied: Bool?
    let usedTrainingHistory: Bool?
    let personalizationSource: String?
}

// MARK: - Generation Status / Quota

/// Response from GET /api/ai/generation-status
struct GenerationStatusResponse: Codable {
    let generationsUsed: Int
    let generationsLimit: Int
    let generationsRemaining: Int
    let resetsAt: String
    let tier: String
}

// MARK: - Strength Profile

/// Request body for PUT /api/ai/strength-profile
struct StrengthProfileRequest: Codable {
    let entries: [StrengthDataEntry]
}

/// Response from GET /api/ai/strength-profile
struct StrengthProfileResponse: Codable {
    let entries: [StrengthProfileEntryDTO]
}

/// A strength profile entry returned from the server (includes matched exercise ID)
struct StrengthProfileEntryDTO: Codable {
    let exerciseName: String
    let weight: Double
    let unit: String
    let reps: Int
    let sets: Int
    let matchedExerciseId: String?
}

// MARK: - Enums for Picker Options

/// Training goals available for AI generation
enum AITrainingGoal: String, CaseIterable, Identifiable {
    case hypertrophy
    case strength
    case endurance
    case general
    case powerbuilding

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hypertrophy: return "Hypertrophy"
        case .strength: return "Strength"
        case .endurance: return "Endurance"
        case .general: return "General"
        case .powerbuilding: return "Powerbuilding"
        }
    }

    var icon: String {
        switch self {
        case .hypertrophy: return "figure.strengthtraining.traditional"
        case .strength: return "dumbbell.fill"
        case .endurance: return "heart.fill"
        case .general: return "figure.mixed.cardio"
        case .powerbuilding: return "bolt.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .hypertrophy: return "Muscle growth"
        case .strength: return "Max strength"
        case .endurance: return "Stamina"
        case .general: return "Overall fitness"
        case .powerbuilding: return "Size & strength"
        }
    }
}

/// Experience levels for AI generation
enum AIExperienceLevel: String, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

/// Equipment options for AI generation
enum AIEquipment: String, CaseIterable, Identifiable {
    case barbell
    case dumbbell
    case cable
    case machine
    case bodyweight
    case bands
    case kettlebell
    case smith_machine

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .cable: return "Cable"
        case .machine: return "Machine"
        case .bodyweight: return "Bodyweight"
        case .bands: return "Bands"
        case .kettlebell: return "Kettlebell"
        case .smith_machine: return "Smith Machine"
        }
    }

    var icon: String {
        switch self {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .cable: return "cable.connector"
        case .machine: return "gearshape.fill"
        case .bodyweight: return "figure.walk"
        case .bands: return "circle.dotted"
        case .kettlebell: return "scalemass.fill"
        case .smith_machine: return "square.stack.3d.up.fill"
        }
    }
}

/// Predefined split type suggestions
enum AISplitSuggestion: String, CaseIterable, Identifiable {
    case pushPullLegs = "Push Pull Legs"
    case upperLower = "Upper Lower"
    case fullBody = "Full Body"
    case broSplit = "Bro Split"

    var id: String { rawValue }
}

// MARK: - AI Response → Domain Model Mapping

enum AIGeneratedProgramMapper {

    static func toDomain(_ dto: AIGeneratedProgramDTO) -> Program {
        let workouts = (dto.workouts ?? []).enumerated().map { index, workoutDTO in
            toDomain(workoutDTO, index: index)
        }

        return Program(
            id: UUID(),
            serverId: dto.id,
            name: dto.name,
            description: dto.description,
            daysPerWeek: dto.daysPerWeek,
            durationWeeks: dto.durationWeeks,
            workouts: workouts,
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: false,
            isAiGenerated: dto.isAiGenerated ?? true,
            createdAt: parseDate(dto.createdAt) ?? Date(),
            updatedAt: parseDate(dto.updatedAt) ?? Date(),
            lastFetchedAt: Date()
        )
    }

    static func toDomain(_ dto: AIGeneratedWorkoutDTO, index: Int) -> ProgramWorkout {
        let template = dto.template.map { toDomain($0) }
        return ProgramWorkout(
            id: UUID(),
            serverId: "",
            dayNumber: dto.dayNumber,
            dayLabel: dto.dayLabel,
            templateServerId: dto.template?.id ?? "",
            template: template
        )
    }

    static func toDomain(_ dto: AIGeneratedTemplateDTO) -> Template {
        let exercises = (dto.exercises ?? []).enumerated().map { index, exerciseDTO in
            toDomain(exerciseDTO, orderIndex: index)
        }

        return Template(
            id: UUID(),
            serverId: dto.id ?? "",
            name: dto.name ?? "Workout",
            description: dto.description,
            exercises: exercises,
            isPublic: false,
            isAiGenerated: true,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: Date()
        )
    }

    static func toDomain(_ dto: AIGeneratedExerciseDTO, orderIndex: Int) -> TemplateExercise {
        // Create a stub ExerciseLibraryItem so displayName works
        // (the AI response provides exercise names directly)
        let stubLibraryItem = dto.name.map { name in
            ExerciseLibraryItem(
                id: UUID(),
                serverId: dto.exerciseId ?? "",
                name: name,
                primaryMuscles: [],
                secondaryMuscles: [],
                equipment: nil,
                difficulty: nil,
                movementPattern: nil,
                exerciseType: nil,
                instructions: nil,
                videoUrl: nil,
                thumbnailUrl: nil,
                popularityScore: 0,
                lastFetchedAt: nil
            )
        }

        return TemplateExercise(
            id: UUID(),
            serverId: "",
            exerciseServerId: dto.exerciseId ?? "",
            exerciseLibraryItem: stubLibraryItem,
            orderIndex: orderIndex,
            warmupSets: dto.warmupSets,
            workingSets: dto.workingSets ?? 3,
            targetReps: dto.targetReps,
            restSeconds: dto.restSeconds,
            notes: dto.notes
        )
    }

    private static func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
