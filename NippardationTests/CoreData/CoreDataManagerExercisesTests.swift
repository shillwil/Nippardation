//
//  CoreDataManagerExercisesTests.swift
//  NippardationTests
//
//  Tests for CoreDataManager+Exercises extension
//

import Testing
import Foundation
import CoreData
@testable import Nippardation

@Suite("CoreDataManager+Exercises Tests")
struct CoreDataManagerExercisesTests {

    // MARK: - Cache Operations

    @Test("Cache exercises saves items to Core Data")
    func testCacheExercisesSavesItems() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let exercises = [
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-1", name: "Bench Press"),
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-2", name: "Squat"),
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-3", name: "Deadlift")
        ]

        try await manager.cacheExercises(exercises)

        let cached = manager.fetchCachedExercises()
        #expect(cached.count == 3)
    }

    @Test("Cache exercises updates existing items")
    func testCacheExercisesUpdatesExisting() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        // Cache initial version
        let initial = CoreDataTestHelper.createSampleExerciseLibraryItem(
            serverId: "ex-1",
            name: "Bench Press",
            popularityScore: 50
        )
        try await manager.cacheExercises([initial])

        // Cache updated version with same serverId
        let updated = CoreDataTestHelper.createSampleExerciseLibraryItem(
            serverId: "ex-1",
            name: "Bench Press - Updated",
            popularityScore: 100
        )
        try await manager.cacheExercises([updated])

        let cached = manager.fetchCachedExercises()
        #expect(cached.count == 1)
        #expect(cached.first?.name == "Bench Press - Updated")
        #expect(cached.first?.popularityScore == 100)
    }

    @Test("Fetch cached exercise by server ID")
    func testFetchCachedExerciseByServerId() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let exercise = CoreDataTestHelper.createSampleExerciseLibraryItem(
            serverId: "unique-id-123",
            name: "Lat Pulldown"
        )
        try await manager.cacheExercises([exercise])

        let fetched = manager.fetchCachedExercise(serverId: "unique-id-123")
        #expect(fetched != nil)
        #expect(fetched?.name == "Lat Pulldown")
    }

    @Test("Fetch cached exercise returns nil for non-existent ID")
    func testFetchCachedExerciseReturnsNilForNonExistent() {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let fetched = manager.fetchCachedExercise(serverId: "does-not-exist")
        #expect(fetched == nil)
    }

    // MARK: - Filter Operations

    @Test("Fetch cached exercises with search filter")
    func testFetchCachedExercisesWithSearchFilter() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let exercises = [
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-1", name: "Bench Press"),
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-2", name: "Incline Bench Press"),
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-3", name: "Squat")
        ]
        try await manager.cacheExercises(exercises)

        let filter = ExerciseFilter(searchText: "bench")
        let filtered = manager.fetchCachedExercises(filter: filter)

        #expect(filtered.count == 2)
        #expect(filtered.allSatisfy { $0.name?.lowercased().contains("bench") ?? false })
    }

    @Test("Fetch cached exercises with equipment filter")
    func testFetchCachedExercisesWithEquipmentFilter() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let exercises = [
            CoreDataTestHelper.createSampleExerciseLibraryItem(
                serverId: "ex-1",
                name: "Barbell Curl",
                equipment: .barbell
            ),
            CoreDataTestHelper.createSampleExerciseLibraryItem(
                serverId: "ex-2",
                name: "Dumbbell Curl",
                equipment: .dumbbell
            )
        ]
        try await manager.cacheExercises(exercises)

        let filter = ExerciseFilter(equipment: [.barbell])
        let filtered = manager.fetchCachedExercises(filter: filter)

        #expect(filtered.count == 1)
        #expect(filtered.first?.equipment == "barbell")
    }

    @Test("Fetch cached exercises with muscle group filter")
    func testFetchCachedExercisesWithMuscleGroupFilter() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let exercises = [
            CoreDataTestHelper.createSampleExerciseLibraryItem(
                serverId: "ex-1",
                name: "Bench Press",
                primaryMuscles: [.chest]
            ),
            CoreDataTestHelper.createSampleExerciseLibraryItem(
                serverId: "ex-2",
                name: "Squat",
                primaryMuscles: [.quads, .glutes]
            )
        ]
        try await manager.cacheExercises(exercises)

        let filter = ExerciseFilter(muscleGroups: [.chest])
        let filtered = manager.fetchCachedExercises(filter: filter)

        #expect(filtered.count == 1)
        #expect(filtered.first?.name == "Bench Press")
    }

    // MARK: - Popular Exercises

    @Test("Fetch popular exercises returns sorted by popularity")
    func testFetchPopularExercisesReturnsSortedByPopularity() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let exercises = [
            CoreDataTestHelper.createSampleExerciseLibraryItem(
                serverId: "ex-1",
                name: "Low Popularity",
                popularityScore: 10
            ),
            CoreDataTestHelper.createSampleExerciseLibraryItem(
                serverId: "ex-2",
                name: "High Popularity",
                popularityScore: 100
            ),
            CoreDataTestHelper.createSampleExerciseLibraryItem(
                serverId: "ex-3",
                name: "Medium Popularity",
                popularityScore: 50
            )
        ]
        try await manager.cacheExercises(exercises)

        let popular = manager.fetchPopularCachedExercises(limit: 3)

        #expect(popular.count == 3)
        #expect(popular[0].name == "High Popularity")
        #expect(popular[1].name == "Medium Popularity")
        #expect(popular[2].name == "Low Popularity")
    }

    @Test("Fetch popular exercises respects limit")
    func testFetchPopularExercisesRespectsLimit() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let exercises = (1...10).map { i in
            CoreDataTestHelper.createSampleExerciseLibraryItem(
                serverId: "ex-\(i)",
                name: "Exercise \(i)",
                popularityScore: i * 10
            )
        }
        try await manager.cacheExercises(exercises)

        let popular = manager.fetchPopularCachedExercises(limit: 3)
        #expect(popular.count == 3)
    }

    // MARK: - Exercises by Muscle

    @Test("Fetch exercises by muscle group")
    func testFetchExercisesByMuscleGroup() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let exercises = [
            CoreDataTestHelper.createSampleExerciseLibraryItem(
                serverId: "ex-1",
                name: "Lat Pulldown",
                primaryMuscles: [.back]
            ),
            CoreDataTestHelper.createSampleExerciseLibraryItem(
                serverId: "ex-2",
                name: "Bench Press",
                primaryMuscles: [.chest]
            ),
            CoreDataTestHelper.createSampleExerciseLibraryItem(
                serverId: "ex-3",
                name: "Barbell Row",
                primaryMuscles: [.back]
            )
        ]
        try await manager.cacheExercises(exercises)

        let backExercises = manager.fetchCachedExercisesByMuscle(.back, limit: 10)

        #expect(backExercises.count == 2)
        #expect(backExercises.allSatisfy { exercise in
            exercise.primaryMusclesArray.contains("back")
        })
    }

    // MARK: - Clear Cache

    @Test("Clear exercise cache removes all items")
    func testClearExerciseCacheRemovesAllItems() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let exercises = [
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-1"),
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-2")
        ]
        try await manager.cacheExercises(exercises)

        // Verify items exist
        let beforeClear = manager.fetchCachedExercises()
        #expect(beforeClear.count == 2)

        // Clear cache
        try await manager.clearExerciseCache()

        // Verify items removed
        let afterClear = manager.fetchCachedExercises()
        #expect(afterClear.count == 0)
    }

    // MARK: - Domain Conversion

    @Test("toDomain correctly converts CDExerciseLibrary to ExerciseLibraryItem")
    func testToDomainConvertsCorrectly() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let original = CoreDataTestHelper.createSampleExerciseLibraryItem(
            serverId: "convert-test",
            name: "Cable Fly",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            equipment: .cable,
            difficulty: .intermediate,
            popularityScore: 75
        )
        try await manager.cacheExercises([original])

        guard let cdExercise = manager.fetchCachedExercise(serverId: "convert-test") else {
            Issue.record("Failed to fetch cached exercise")
            return
        }

        let converted = manager.toDomain(cdExercise)

        #expect(converted.serverId == "convert-test")
        #expect(converted.name == "Cable Fly")
        #expect(converted.primaryMuscles == [.chest])
        #expect(converted.secondaryMuscles == [.shoulders])
        #expect(converted.equipment == .cable)
        #expect(converted.difficulty == .intermediate)
        #expect(converted.popularityScore == 75)
    }
}
