//
//  TemplateMapper.swift
//  Nippardation
//
//  Phase 0: Maps between TemplateDTO and Template domain model
//

import Foundation

/// Maps between API DTOs and domain models for templates
enum TemplateMapper {

    // MARK: - DTO to Domain

    /// Converts a TemplateDTO to a Template domain model
    static func toDomain(_ dto: TemplateDTO) -> Template {
        let exercises = (dto.exercises ?? []).map { TemplateExerciseMapper.toDomain($0) }
        var template = Template(
            id: UUID(),
            serverId: dto.id,
            name: dto.name,
            description: dto.description,
            exercises: exercises,
            isPublic: dto.isPublic ?? false,
            isAiGenerated: dto.isAiGenerated ?? false,
            createdAt: parseDate(dto.createdAt) ?? Date(),
            updatedAt: parseDate(dto.updatedAt) ?? Date(),
            lastFetchedAt: Date()
        )
        // Preserve exercise count from API when exercises array is empty (list endpoints)
        if exercises.isEmpty, let count = dto.exerciseCount {
            template._knownExerciseCount = count
        }
        return template
    }

    /// Converts multiple TemplateDTOs to Templates
    static func toDomain(_ dtos: [TemplateDTO]) -> [Template] {
        dtos.map { toDomain($0) }
    }

    // MARK: - Domain to DTO

    /// Converts a Template to a TemplateCreateRequest for creating/updating
    static func toCreateRequest(_ template: Template) -> TemplateCreateRequest {
        TemplateCreateRequest(
            name: template.name,
            description: template.description,
            exercises: template.exercises.map { TemplateExerciseMapper.toCreateDTO($0) },
            isPublic: template.isPublic
        )
    }

    // MARK: - Date Parsing

    /// Parses ISO 8601 date string
    private static func parseDate(_ string: String?) -> Date? {
        guard let string = string else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}

// MARK: - Template Exercise Mapper

/// Maps between TemplateExerciseDTO and TemplateExercise
enum TemplateExerciseMapper {

    /// Converts a TemplateExerciseDTO to a TemplateExercise domain model
    static func toDomain(_ dto: TemplateExerciseDTO) -> TemplateExercise {
        TemplateExercise(
            id: UUID(),
            serverId: dto.id,
            exerciseServerId: dto.exerciseId,
            exerciseLibraryItem: dto.exercise.map { ExerciseMapper.toDomain($0) },
            orderIndex: dto.orderIndex,
            warmupSets: dto.warmupSets,
            workingSets: dto.workingSets,
            targetReps: dto.targetReps,
            restSeconds: dto.restSeconds,
            notes: dto.notes
        )
    }

    /// Converts a TemplateExercise to a TemplateExerciseCreateDTO
    static func toCreateDTO(_ exercise: TemplateExercise) -> TemplateExerciseCreateDTO {
        TemplateExerciseCreateDTO(
            exerciseId: exercise.exerciseServerId,
            orderIndex: exercise.orderIndex,
            warmupSets: exercise.warmupSets,
            workingSets: exercise.workingSets,
            targetReps: exercise.targetReps,
            restSeconds: exercise.restSeconds,
            notes: exercise.notes
        )
    }
}
