//
//  MockExerciseRepository.swift
//  Nippardation
//
//  Phase 0: Mock implementation of ExerciseRepositoryProtocol for testing and previews
//

import Foundation

/// Mock implementation of ExerciseRepositoryProtocol
/// Provides sample data for testing and SwiftUI previews
@MainActor
final class MockExerciseRepository: ExerciseRepositoryProtocol {

    // MARK: - Mock Data Storage

    private var exercises: [ExerciseLibraryItem] = MockExerciseRepository.sampleExercises
    private var shouldFail = false
    private var delay: TimeInterval = 0

    // MARK: - Configuration

    /// Configures the mock to fail all operations
    func setFailure(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    /// Configures artificial delay for simulating network latency
    func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }

    // MARK: - ExerciseRepositoryProtocol

    func fetchExercises(
        filter: ExerciseFilter?,
        page: Int,
        forceRefresh: Bool
    ) async throws -> PaginatedResult<ExerciseLibraryItem> {
        try await simulateNetworkCall()

        var filtered = exercises

        if let filter = filter {
            if !filter.searchText.isEmpty {
                filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(filter.searchText) }
            }
            if !filter.muscleGroups.isEmpty {
                filtered = filtered.filter { exercise in
                    !exercise.primaryMuscles.filter { filter.muscleGroups.contains($0) }.isEmpty
                }
            }
            if !filter.equipment.isEmpty {
                filtered = filtered.filter { exercise in
                    guard let equipment = exercise.equipment else { return false }
                    return filter.equipment.contains(equipment)
                }
            }
            if let difficulty = filter.difficulty {
                filtered = filtered.filter { $0.difficulty == difficulty }
            }
        }

        let pageSize = 20
        let start = (page - 1) * pageSize
        let end = min(start + pageSize, filtered.count)
        let pageItems = start < filtered.count ? Array(filtered[start..<end]) : []
        let totalPages = (filtered.count + pageSize - 1) / pageSize

        return PaginatedResult(
            items: pageItems,
            page: page,
            totalPages: max(1, totalPages),
            totalItems: filtered.count
        )
    }

    func fetchExercise(
        serverId: String,
        forceRefresh: Bool
    ) async throws -> ExerciseLibraryItem {
        try await simulateNetworkCall()

        guard let exercise = exercises.first(where: { $0.serverId == serverId }) else {
            throw RepositoryError.notFound
        }
        return exercise
    }

    func searchExercises(
        query: String,
        limit: Int
    ) async throws -> [ExerciseLibraryItem] {
        try await simulateNetworkCall()

        let results = exercises.filter { $0.name.localizedCaseInsensitiveContains(query) }
        return Array(results.prefix(limit))
    }

    func getCachedExercises(filter: ExerciseFilter?) -> [ExerciseLibraryItem] {
        exercises
    }

    func getCachedExercise(serverId: String) -> ExerciseLibraryItem? {
        exercises.first { $0.serverId == serverId }
    }

    func clearCache() async throws {
        // No-op for mock
    }

    func fetchPopularExercises(limit: Int) async throws -> [ExerciseLibraryItem] {
        try await simulateNetworkCall()
        return Array(exercises.sorted { $0.popularityScore > $1.popularityScore }.prefix(limit))
    }

    func fetchExercisesByMuscle(
        _ muscleGroup: MuscleGroup,
        limit: Int
    ) async throws -> [ExerciseLibraryItem] {
        try await simulateNetworkCall()
        let filtered = exercises.filter { $0.primaryMuscles.contains(muscleGroup) }
        return Array(filtered.prefix(limit))
    }

    // MARK: - Helpers

    private func simulateNetworkCall() async throws {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if shouldFail {
            throw RepositoryError.networkUnavailable
        }
    }
}

// MARK: - Sample Data

extension MockExerciseRepository {

    static let sampleExercises: [ExerciseLibraryItem] = [
        ExerciseLibraryItem(
            id: UUID(),
            serverId: "ex_001",
            name: "Barbell Bench Press",
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders],
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .push,
            exerciseType: .compound,
            instructions: "Lie on bench, grip bar slightly wider than shoulders, lower to chest, press up.",
            videoUrl: URL(string: "https://example.com/videos/bench_press.mp4"),
            thumbnailUrl: URL(string: "https://example.com/thumbs/bench_press.jpg"),
            popularityScore: 95,
            lastFetchedAt: Date()
        ),
        ExerciseLibraryItem(
            id: UUID(),
            serverId: "ex_002",
            name: "Barbell Back Squat",
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings],
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .squat,
            exerciseType: .compound,
            instructions: "Bar on upper back, feet shoulder width, squat down keeping chest up.",
            videoUrl: URL(string: "https://example.com/videos/squat.mp4"),
            thumbnailUrl: URL(string: "https://example.com/thumbs/squat.jpg"),
            popularityScore: 98,
            lastFetchedAt: Date()
        ),
        ExerciseLibraryItem(
            id: UUID(),
            serverId: "ex_003",
            name: "Conventional Deadlift",
            primaryMuscles: [.back, .hamstrings],
            secondaryMuscles: [.glutes, .quads],
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .hinge,
            exerciseType: .compound,
            instructions: "Grip bar outside knees, drive through heels, keep back straight.",
            videoUrl: URL(string: "https://example.com/videos/deadlift.mp4"),
            thumbnailUrl: URL(string: "https://example.com/thumbs/deadlift.jpg"),
            popularityScore: 97,
            lastFetchedAt: Date()
        ),
        ExerciseLibraryItem(
            id: UUID(),
            serverId: "ex_004",
            name: "Pull-Up",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps],
            equipment: .pullupBar,
            difficulty: .intermediate,
            movementPattern: .pull,
            exerciseType: .compound,
            instructions: "Hang from bar, pull up until chin over bar, lower with control.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 90,
            lastFetchedAt: Date()
        ),
        ExerciseLibraryItem(
            id: UUID(),
            serverId: "ex_005",
            name: "Dumbbell Lateral Raise",
            primaryMuscles: [.shoulders],
            secondaryMuscles: [],
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .isolation,
            exerciseType: .isolation,
            instructions: "Stand with dumbbells at sides, raise arms to shoulder height.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 75,
            lastFetchedAt: Date()
        ),
        ExerciseLibraryItem(
            id: UUID(),
            serverId: "ex_006",
            name: "Barbell Curl",
            primaryMuscles: [.biceps],
            secondaryMuscles: [],
            equipment: .barbell,
            difficulty: .beginner,
            movementPattern: .isolation,
            exerciseType: .isolation,
            instructions: "Stand holding barbell, curl up keeping elbows stationary.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 80,
            lastFetchedAt: Date()
        ),
        ExerciseLibraryItem(
            id: UUID(),
            serverId: "ex_007",
            name: "Tricep Pushdown",
            primaryMuscles: [.triceps],
            secondaryMuscles: [],
            equipment: .cable,
            difficulty: .beginner,
            movementPattern: .isolation,
            exerciseType: .isolation,
            instructions: "Face cable machine, push bar down until arms straight.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 78,
            lastFetchedAt: Date()
        ),
        ExerciseLibraryItem(
            id: UUID(),
            serverId: "ex_008",
            name: "Leg Press",
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .hamstrings],
            equipment: .machine,
            difficulty: .beginner,
            movementPattern: .squat,
            exerciseType: .compound,
            instructions: "Sit in machine, press platform away, lower with control.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 85,
            lastFetchedAt: Date()
        ),
        ExerciseLibraryItem(
            id: UUID(),
            serverId: "ex_009",
            name: "Romanian Deadlift",
            primaryMuscles: [.hamstrings],
            secondaryMuscles: [.glutes, .back],
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .hinge,
            exerciseType: .compound,
            instructions: "Hold bar, hinge at hips keeping legs slightly bent, lower until stretch in hamstrings.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 88,
            lastFetchedAt: Date()
        ),
        ExerciseLibraryItem(
            id: UUID(),
            serverId: "ex_010",
            name: "Cable Crunch",
            primaryMuscles: [.abs],
            secondaryMuscles: [],
            equipment: .cable,
            difficulty: .beginner,
            movementPattern: .isolation,
            exerciseType: .isolation,
            instructions: "Kneel facing cable, crunch down bringing elbows to knees.",
            videoUrl: nil,
            thumbnailUrl: nil,
            popularityScore: 70,
            lastFetchedAt: Date()
        )
    ]
}
