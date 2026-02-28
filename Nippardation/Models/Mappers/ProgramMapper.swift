//
//  ProgramMapper.swift
//  Nippardation
//
//  Phase 0: Maps between ProgramDTO and Program domain model
//

import Foundation

/// Maps between API DTOs and domain models for programs
enum ProgramMapper {

    // MARK: - DTO to Domain

    /// Converts a ProgramDTO to a Program domain model
    static func toDomain(_ dto: ProgramDTO) -> Program {
        Program(
            id: UUID(),
            serverId: dto.id,
            name: dto.name,
            description: dto.description,
            daysPerWeek: dto.daysPerWeek,
            durationWeeks: dto.durationWeeks,
            workouts: (dto.workouts ?? []).map { ProgramWorkoutMapper.toDomain($0) },
            isActive: dto.isActive ?? false,
            currentDayIndex: dto.currentDayIndex ?? 0,
            timesCompleted: dto.timesCompleted ?? 0,
            isPublic: dto.isPublic ?? false,
            isAiGenerated: dto.isAiGenerated ?? false,
            createdAt: parseDate(dto.createdAt) ?? Date(),
            updatedAt: parseDate(dto.updatedAt) ?? Date(),
            lastFetchedAt: Date()
        )
    }

    /// Converts multiple ProgramDTOs to Programs
    static func toDomain(_ dtos: [ProgramDTO]) -> [Program] {
        dtos.map { toDomain($0) }
    }

    // MARK: - Domain to DTO

    /// Converts a Program to a ProgramCreateRequest for creating/updating
    static func toCreateRequest(_ program: Program) -> ProgramCreateRequest {
        ProgramCreateRequest(
            name: program.name,
            description: program.description,
            daysPerWeek: program.daysPerWeek,
            durationWeeks: program.durationWeeks,
            workouts: program.workouts.map { ProgramWorkoutMapper.toCreateDTO($0) },
            isPublic: program.isPublic
        )
    }

    /// Converts a Program to a ProgramProgressUpdateRequest
    static func toProgressUpdateRequest(_ program: Program) -> ProgramProgressUpdateRequest {
        ProgramProgressUpdateRequest(
            currentDayIndex: program.currentDayIndex,
            timesCompleted: program.timesCompleted
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

// MARK: - Program Workout Mapper

/// Maps between ProgramWorkoutDTO and ProgramWorkout
enum ProgramWorkoutMapper {

    /// Converts a ProgramWorkoutDTO to a ProgramWorkout domain model
    static func toDomain(_ dto: ProgramWorkoutDTO) -> ProgramWorkout {
        ProgramWorkout(
            id: UUID(),
            serverId: dto.id,
            dayNumber: dto.dayNumber,
            dayLabel: dto.dayLabel,
            templateServerId: dto.templateId,
            template: dto.template.map { TemplateMapper.toDomain($0) }
        )
    }

    /// Converts a ProgramWorkout to a ProgramWorkoutCreateDTO
    static func toCreateDTO(_ workout: ProgramWorkout) -> ProgramWorkoutCreateDTO {
        ProgramWorkoutCreateDTO(
            dayNumber: workout.dayNumber,
            dayLabel: workout.dayLabel,
            templateId: workout.templateServerId
        )
    }
}
