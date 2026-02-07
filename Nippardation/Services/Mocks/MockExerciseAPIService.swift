//
//  MockExerciseAPIService.swift
//  Nippardation
//
//  Phase 0 Extension: Mock implementation of ExerciseAPIServiceProtocol for testing and development
//

import Foundation

/// Mock implementation of ExerciseAPIServiceProtocol for testing and development
final class MockExerciseAPIService: ExerciseAPIServiceProtocol, @unchecked Sendable {

    // MARK: - Test Configuration

    /// When true, all methods throw errorToThrow
    var shouldThrowError = false

    /// Error to throw when shouldThrowError is true
    var errorToThrow: RepositoryError = .networkUnavailable

    /// Artificial delay to simulate network latency (seconds)
    var fetchDelay: TimeInterval = 0.1

    /// Exercises to return (defaults to sample data)
    var exerciseDTOs: [ExerciseDTO]?

    /// Filter options to return
    var filterOptionsDTO: ExerciseFilterOptionsDTO?

    // MARK: - Call Tracking

    private(set) var fetchExercisesCallCount = 0
    private(set) var fetchExerciseCallCount = 0
    private(set) var fetchFilterOptionsCallCount = 0
    private(set) var recordUsageCallCount = 0
    private(set) var lastFilters: ExerciseFilters?
    private(set) var lastRecordedExerciseId: String?

    // MARK: - Protocol Implementation

    func fetchExercises(
        filters: ExerciseFilters?,
        cursor: String?,
        limit: Int
    ) async throws -> (exercises: [ExerciseDTO], pagination: PaginationInfo) {
        fetchExercisesCallCount += 1
        lastFilters = filters

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        let dtos = exerciseDTOs ?? Self.sampleExerciseDTOs

        // Apply basic filtering for realistic mock behavior
        var filtered = dtos
        if let filters = filters {
            if !filters.muscleGroups.isEmpty {
                filtered = filtered.filter { dto in
                    let primary = dto.primaryMuscles ?? []
                    let targetMuscles = filters.includePrimaryOnly
                        ? Set(primary)
                        : Set(primary + (dto.secondaryMuscles ?? []))
                    return !filters.muscleGroups.isDisjoint(with: targetMuscles)
                }
            }

            if !filters.equipment.isEmpty {
                filtered = filtered.filter { dto in
                    guard let equip = dto.equipment else { return false }
                    return filters.equipment.contains(equip)
                }
            }

            if !filters.difficulties.isEmpty {
                filtered = filtered.filter { dto in
                    guard let diff = dto.difficulty else { return false }
                    return filters.difficulties.contains(diff)
                }
            }

            if !filters.searchQuery.isEmpty {
                let query = filters.searchQuery.lowercased()
                filtered = filtered.filter { $0.name.lowercased().contains(query) }
            }
        }

        // Apply pagination
        let startIndex = cursor != nil ? min(Int(cursor!) ?? 0, filtered.count) : 0
        let endIndex = min(startIndex + limit, filtered.count)
        let page = startIndex < filtered.count ? Array(filtered[startIndex..<endIndex]) : []
        let hasMore = endIndex < filtered.count
        let nextCursor = hasMore ? String(endIndex) : nil

        return (page, PaginationInfo(nextCursor: nextCursor, hasMore: hasMore))
    }

    func fetchExercise(id: String) async throws -> ExerciseDTO {
        fetchExerciseCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        let dtos = exerciseDTOs ?? Self.sampleExerciseDTOs
        guard let dto = dtos.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        return dto
    }

    func fetchFilterOptions() async throws -> ExerciseFilterOptionsDTO {
        fetchFilterOptionsCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        if let custom = filterOptionsDTO {
            return custom
        }

        return Self.sampleFilterOptions
    }

    func recordUsage(exerciseId: String) async throws {
        recordUsageCallCount += 1
        lastRecordedExerciseId = exerciseId

        if shouldThrowError {
            throw errorToThrow
        }

        // No-op in mock - real implementation updates server
    }

    /// Reset all tracking state
    func reset() {
        fetchExercisesCallCount = 0
        fetchExerciseCallCount = 0
        fetchFilterOptionsCallCount = 0
        recordUsageCallCount = 0
        lastFilters = nil
        lastRecordedExerciseId = nil
        shouldThrowError = false
        exerciseDTOs = nil
        filterOptionsDTO = nil
    }
}

// MARK: - Sample Data

extension MockExerciseAPIService {

    static let sampleExerciseDTOs: [ExerciseDTO] = [
        ExerciseDTO(
            id: "ex_001",
            name: "Barbell Bench Press",
            primaryMuscles: ["chest"],
            secondaryMuscles: ["triceps", "shoulders"],
            equipment: "barbell",
            difficulty: "intermediate",
            movementPattern: "push",
            exerciseType: "compound",
            instructions: "Lie on bench, grip bar slightly wider than shoulders, lower to chest, press up.",
            videoUrl: "https://example.com/videos/bench_press.mp4",
            thumbnailUrl: "https://example.com/thumbs/bench_press.jpg",
            popularityScore: 95,
            createdAt: nil,
            updatedAt: nil,
            muscleGroups: nil,
            isCustom: nil,
            createdBy: nil
        ),
        ExerciseDTO(
            id: "ex_002",
            name: "Barbell Back Squat",
            primaryMuscles: ["quads", "glutes"],
            secondaryMuscles: ["hamstrings"],
            equipment: "barbell",
            difficulty: "intermediate",
            movementPattern: "squat",
            exerciseType: "compound",
            instructions: "Bar on upper back, feet shoulder width, squat down keeping chest up.",
            videoUrl: "https://example.com/videos/squat.mp4",
            thumbnailUrl: "https://example.com/thumbs/squat.jpg",
            popularityScore: 98,
            createdAt: nil,
            updatedAt: nil,
            muscleGroups: nil,
            isCustom: nil,
            createdBy: nil
        ),
        ExerciseDTO(
            id: "ex_003",
            name: "Conventional Deadlift",
            primaryMuscles: ["back", "hamstrings"],
            secondaryMuscles: ["glutes", "quads"],
            equipment: "barbell",
            difficulty: "intermediate",
            movementPattern: "hinge",
            exerciseType: "compound",
            instructions: "Grip bar outside knees, drive through heels, keep back straight.",
            videoUrl: "https://example.com/videos/deadlift.mp4",
            thumbnailUrl: "https://example.com/thumbs/deadlift.jpg",
            popularityScore: 97,
            createdAt: nil,
            updatedAt: nil,
            muscleGroups: nil,
            isCustom: nil,
            createdBy: nil
        ),
        ExerciseDTO(
            id: "ex_004",
            name: "Pull-Up",
            primaryMuscles: ["back"],
            secondaryMuscles: ["biceps"],
            equipment: "pullup_bar",
            difficulty: "intermediate",
            movementPattern: "pull",
            exerciseType: "compound",
            instructions: "Hang from bar, pull up until chin over bar, lower with control.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 90,
            createdAt: nil,
            updatedAt: nil,
            muscleGroups: nil,
            isCustom: nil,
            createdBy: nil
        ),
        ExerciseDTO(
            id: "ex_005",
            name: "Dumbbell Lateral Raise",
            primaryMuscles: ["shoulders"],
            secondaryMuscles: nil,
            equipment: "dumbbell",
            difficulty: "beginner",
            movementPattern: "isolation",
            exerciseType: "isolation",
            instructions: "Stand with dumbbells at sides, raise arms to shoulder height.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 75,
            createdAt: nil,
            updatedAt: nil,
            muscleGroups: nil,
            isCustom: nil,
            createdBy: nil
        ),
        ExerciseDTO(
            id: "ex_006",
            name: "Barbell Curl",
            primaryMuscles: ["biceps"],
            secondaryMuscles: nil,
            equipment: "barbell",
            difficulty: "beginner",
            movementPattern: "isolation",
            exerciseType: "isolation",
            instructions: "Stand holding barbell, curl up keeping elbows stationary.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 80,
            createdAt: nil,
            updatedAt: nil,
            muscleGroups: nil,
            isCustom: nil,
            createdBy: nil
        ),
        ExerciseDTO(
            id: "ex_007",
            name: "Tricep Pushdown",
            primaryMuscles: ["triceps"],
            secondaryMuscles: nil,
            equipment: "cable",
            difficulty: "beginner",
            movementPattern: "isolation",
            exerciseType: "isolation",
            instructions: "Face cable machine, push bar down until arms straight.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 78,
            createdAt: nil,
            updatedAt: nil,
            muscleGroups: nil,
            isCustom: nil,
            createdBy: nil
        ),
        ExerciseDTO(
            id: "ex_008",
            name: "Leg Press",
            primaryMuscles: ["quads"],
            secondaryMuscles: ["glutes", "hamstrings"],
            equipment: "machine",
            difficulty: "beginner",
            movementPattern: "squat",
            exerciseType: "compound",
            instructions: "Sit in machine, press platform away, lower with control.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 85,
            createdAt: nil,
            updatedAt: nil,
            muscleGroups: nil,
            isCustom: nil,
            createdBy: nil
        ),
        ExerciseDTO(
            id: "ex_009",
            name: "Romanian Deadlift",
            primaryMuscles: ["hamstrings"],
            secondaryMuscles: ["glutes", "back"],
            equipment: "barbell",
            difficulty: "intermediate",
            movementPattern: "hinge",
            exerciseType: "compound",
            instructions: "Hold bar, hinge at hips keeping legs slightly bent, lower until stretch in hamstrings.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 88,
            createdAt: nil,
            updatedAt: nil,
            muscleGroups: nil,
            isCustom: nil,
            createdBy: nil
        ),
        ExerciseDTO(
            id: "ex_010",
            name: "Cable Crunch",
            primaryMuscles: ["abs"],
            secondaryMuscles: nil,
            equipment: "cable",
            difficulty: "beginner",
            movementPattern: "isolation",
            exerciseType: "isolation",
            instructions: "Kneel facing cable, crunch down bringing elbows to knees.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 70,
            createdAt: nil,
            updatedAt: nil,
            muscleGroups: nil,
            isCustom: nil,
            createdBy: nil
        )
    ]

    static let sampleFilterOptions = ExerciseFilterOptionsDTO(
        muscleGroups: [
            FilterOptionDTO(value: "chest", label: "Chest", count: 15),
            FilterOptionDTO(value: "back", label: "Back", count: 20),
            FilterOptionDTO(value: "shoulders", label: "Shoulders", count: 12),
            FilterOptionDTO(value: "biceps", label: "Biceps", count: 10),
            FilterOptionDTO(value: "triceps", label: "Triceps", count: 8),
            FilterOptionDTO(value: "quads", label: "Quads", count: 12),
            FilterOptionDTO(value: "hamstrings", label: "Hamstrings", count: 8),
            FilterOptionDTO(value: "glutes", label: "Glutes", count: 10),
            FilterOptionDTO(value: "abs", label: "Abs", count: 6)
        ],
        difficulties: [
            FilterOptionDTO(value: "beginner", label: "Beginner", count: 40),
            FilterOptionDTO(value: "intermediate", label: "Intermediate", count: 50),
            FilterOptionDTO(value: "advanced", label: "Advanced", count: 20)
        ],
        equipment: [
            FilterOptionDTO(value: "barbell", label: "Barbell", count: 30),
            FilterOptionDTO(value: "dumbbell", label: "Dumbbell", count: 35),
            FilterOptionDTO(value: "cable", label: "Cable", count: 20),
            FilterOptionDTO(value: "machine", label: "Machine", count: 15),
            FilterOptionDTO(value: "bodyweight", label: "Bodyweight", count: 10)
        ],
        movementPatterns: [
            FilterOptionDTO(value: "push", label: "Push", count: 25),
            FilterOptionDTO(value: "pull", label: "Pull", count: 25),
            FilterOptionDTO(value: "squat", label: "Squat", count: 15),
            FilterOptionDTO(value: "hinge", label: "Hinge", count: 15),
            FilterOptionDTO(value: "isolation", label: "Isolation", count: 30)
        ],
        exerciseTypes: [
            FilterOptionDTO(value: "compound", label: "Compound", count: 50),
            FilterOptionDTO(value: "isolation", label: "Isolation", count: 50)
        ]
    )
}
