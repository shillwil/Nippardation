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

    // MARK: - Server ID to UUID Mapping

    /// Namespace UUID for generating deterministic UUIDs from server IDs
    /// Using a fixed namespace ensures the same server ID always produces the same UUID
    private static let namespaceUUID = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!

    /// Generates a deterministic UUID from a server ID string
    /// If the server ID is already a valid UUID, it's used directly
    /// Otherwise, a deterministic UUID is generated using XOR-based hashing
    /// Note: This is NOT a standard UUID v5 (which requires SHA-1). It uses a simpler
    /// XOR mixing algorithm that produces consistent UUIDs for the same input but
    /// won't match standard UUID v5 implementations.
    static func uuidFromServerId(_ serverId: String) -> UUID {
        // First try parsing as UUID directly (for client-generated IDs)
        if let uuid = UUID(uuidString: serverId) {
            return uuid
        }

        // Generate deterministic UUID from server ID using XOR-based mixing
        let data = serverId.data(using: .utf8)!
        var hash = [UInt8](repeating: 0, count: 20)

        // Combine namespace and server ID bytes
        let namespaceBytes = withUnsafeBytes(of: namespaceUUID.uuid) { Array($0) }
        let combined = namespaceBytes + Array(data)

        // Create a deterministic hash using XOR mixing (not cryptographic, just for ID generation)
        for i in 0..<min(combined.count, 16) {
            hash[i] = combined[i]
        }
        // Mix in remaining bytes using XOR
        for i in 16..<combined.count {
            hash[i % 16] ^= combined[i]
        }

        // Build UUID from first 16 bytes of hash
        var uuidBytes = (
            hash[0], hash[1], hash[2], hash[3],
            hash[4], hash[5], hash[6], hash[7],
            hash[8], hash[9], hash[10], hash[11],
            hash[12], hash[13], hash[14], hash[15]
        )

        // Set version 8 (custom/experimental) and variant bits per UUID spec
        uuidBytes.6 = (uuidBytes.6 & 0x0F) | 0x80  // Version 8 (custom)
        uuidBytes.8 = (uuidBytes.8 & 0x3F) | 0x80  // Variant (RFC 4122)

        return UUID(uuid: uuidBytes)
    }

    // MARK: - Domain to DTO (for syncing)

    /// Converts a TrackedWorkout to a WorkoutCreateDTO for syncing
    static func toCreateDTO(_ workout: TrackedWorkout, userId: String) -> WorkoutCreateDTO {
        let now = formatDate(Date())
        return WorkoutCreateDTO(
            clientId: workout.id.uuidString,
            userId: userId,
            date: formatDate(workout.date),
            name: workout.workoutTemplate,
            templateName: workout.workoutTemplate,
            startTime: formatDate(workout.startTime ?? workout.date),
            endTime: workout.endTime.map { formatDate($0) },
            durationSeconds: workout.duration.map { Int($0) },
            isCompleted: workout.isCompleted,
            updatedAt: now,
            exercises: workout.trackedExercises.map { exercise in
                WorkoutExerciseMapper.toCreateDTO(exercise, updatedAt: now)
            }
        )
    }

    /// Converts multiple TrackedWorkouts to a WorkoutSyncRequest
    static func toSyncRequest(_ workouts: [TrackedWorkout], userId: String) -> WorkoutSyncRequest {
        WorkoutSyncRequest(
            workouts: workouts.map { toCreateDTO($0, userId: userId) }
        )
    }

    // MARK: - DTO to Domain (from sync)

    /// Converts a WorkoutDTO to a TrackedWorkout
    static func toDomain(_ dto: WorkoutDTO) -> TrackedWorkout {
        let startDate = parseDate(dto.startedAt) ?? Date()
        let endDate = dto.completedAt.flatMap { parseDate($0) }

        return TrackedWorkout(
            id: uuidFromServerId(dto.id),
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
    static func toCreateDTO(_ exercise: TrackedExercise, updatedAt: String) -> WorkoutExerciseCreateDTO {
        WorkoutExerciseCreateDTO(
            clientId: exercise.id.uuidString,
            exerciseName: exercise.exerciseName,
            muscleGroups: exercise.muscleGroups,
            sets: exercise.trackedSets.map { set in
                WorkoutSetMapper.toCreateDTO(set, updatedAt: updatedAt)
            },
            updatedAt: updatedAt
        )
    }

    /// Converts a WorkoutExerciseDTO to a TrackedExercise
    static func toDomain(_ dto: WorkoutExerciseDTO) -> TrackedExercise {
        TrackedExercise(
            id: WorkoutMapper.uuidFromServerId(dto.id),
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
    static func toCreateDTO(_ set: TrackedSet, updatedAt: String) -> WorkoutSetCreateDTO {
        WorkoutSetCreateDTO(
            clientId: set.id.uuidString,
            setType: set.setType.rawValue,
            reps: set.reps,
            weight: set.weight,
            exerciseTypeName: set.exerciseType.name,
            exerciseTypeMuscleGroups: set.exerciseType.muscleGroup.map { $0.rawValue },
            updatedAt: updatedAt
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
