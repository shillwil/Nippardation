//
//  WorkoutMapper.swift
//  Nippardation
//
//  Phase 0: Maps between WorkoutDTO and TrackedWorkout models
//

import Foundation

/// Maps between API DTOs and domain models for completed workouts
/// Bridges the gap between sync DTOs and existing TrackedWorkout models
enum WorkoutMapper {

    // MARK: - Domain to DTO (for syncing)

    /// Converts a TrackedWorkout to a WorkoutCreateDTO for syncing
    static func toCreateDTO(_ workout: TrackedWorkout) -> WorkoutCreateDTO {
        WorkoutCreateDTO(
            clientId: workout.id.uuidString,
            templateId: nil,
            templateName: workout.workoutTemplate,
            startedAt: formatDate(workout.startTime ?? workout.date),
            completedAt: workout.endTime.map { formatDate($0) },
            durationSeconds: workout.duration.map { Int($0) },
            notes: nil,
            exercises: workout.trackedExercises.enumerated().map { index, exercise in
                WorkoutExerciseMapper.toCreateDTO(exercise, orderIndex: index)
            }
        )
    }

    /// Converts multiple TrackedWorkouts to a WorkoutSyncRequest
    static func toSyncRequest(_ workouts: [TrackedWorkout]) -> WorkoutSyncRequest {
        WorkoutSyncRequest(
            workouts: workouts.map { toCreateDTO($0) }
        )
    }

    // MARK: - DTO to Domain (from sync)

    /// Converts a WorkoutDTO to a TrackedWorkout
    static func toDomain(_ dto: WorkoutDTO) -> TrackedWorkout {
        let startDate = parseDate(dto.startedAt) ?? Date()
        let endDate = dto.completedAt.flatMap { parseDate($0) }

        return TrackedWorkout(
            id: UUID(uuidString: dto.id) ?? UUID(),
            userID: nil,
            date: startDate,
            workoutTemplate: dto.templateName ?? "Workout",
            duration: dto.durationSeconds.map { TimeInterval($0) },
            trackedExercises: dto.exercises.map { WorkoutExerciseMapper.toDomain($0) },
            isCompleted: endDate != nil,
            startTime: startDate,
            endTime: endDate
        )
    }

    // MARK: - Date Formatting

    /// Formats a Date to ISO 8601 string
    private static func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    /// Parses ISO 8601 date string
    private static func parseDate(_ string: String) -> Date? {
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

// MARK: - Workout Exercise Mapper

/// Maps between WorkoutExerciseDTO and TrackedExercise
enum WorkoutExerciseMapper {

    /// Converts a TrackedExercise to a WorkoutExerciseCreateDTO
    static func toCreateDTO(_ exercise: TrackedExercise, orderIndex: Int) -> WorkoutExerciseCreateDTO {
        WorkoutExerciseCreateDTO(
            clientId: exercise.id.uuidString,
            exerciseId: nil,
            exerciseName: exercise.exerciseName,
            orderIndex: orderIndex,
            sets: exercise.trackedSets.enumerated().map { setIndex, set in
                WorkoutSetMapper.toCreateDTO(set, setNumber: setIndex + 1)
            },
            notes: nil
        )
    }

    /// Converts a WorkoutExerciseDTO to a TrackedExercise
    static func toDomain(_ dto: WorkoutExerciseDTO) -> TrackedExercise {
        TrackedExercise(
            id: UUID(uuidString: dto.id) ?? UUID(),
            exerciseName: dto.exerciseName,
            muscleGroups: [],
            trackedSets: dto.sets.map { WorkoutSetMapper.toDomain($0) }
        )
    }
}

// MARK: - Workout Set Mapper

/// Maps between WorkoutSetDTO and TrackedSet
enum WorkoutSetMapper {

    /// Converts a TrackedSet to a WorkoutSetCreateDTO
    static func toCreateDTO(_ set: TrackedSet, setNumber: Int) -> WorkoutSetCreateDTO {
        WorkoutSetCreateDTO(
            clientId: set.id.uuidString,
            setNumber: setNumber,
            setType: set.setType.rawValue,
            targetReps: nil,
            completedReps: set.reps,
            weight: set.weight,
            weightUnit: "lbs",
            rpe: nil,
            notes: nil
        )
    }

    /// Converts a WorkoutSetDTO to a TrackedSet
    static func toDomain(_ dto: WorkoutSetDTO) -> TrackedSet {
        // Create a placeholder ExerciseType - will be resolved when full exercise data is available
        let exerciseType = ExerciseType(
            name: "Unknown",
            muscleGroup: []
        )

        return TrackedSet(
            reps: dto.completedReps ?? 0,
            weight: dto.weight ?? 0,
            setType: SetType(rawValue: dto.setType) ?? .working,
            exerciseType: exerciseType
        )
    }
}
