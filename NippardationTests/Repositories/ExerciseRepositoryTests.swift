//
//  ExerciseRepositoryTests.swift
//  NippardationTests
//
//  Tests for ExerciseRepository
//

import Testing
import Foundation
@testable import Nippardation

@Suite("ExerciseRepository Tests")
@MainActor
struct ExerciseRepositoryTests {

    // MARK: - Fetch Exercises

    @Test("Fetch exercises returns items from API")
    func testFetchExercisesReturnsItemsFromAPI() async throws {
        let apiService = MockExerciseAPIService()
        let coreDataManager = CoreDataTestHelper.createInMemoryManager()

        await apiService.setExercises([
            .sample(id: "ex-1", name: "Bench Press"),
            .sample(id: "ex-2", name: "Squat")
        ])

        let repository = ExerciseRepository(
            apiService: apiService,
            coreDataManager: coreDataManager
        )

        let result = try await repository.fetchExercises(
            filter: nil,
            page: 1,
            forceRefresh: true
        )

        #expect(result.items.count == 2)
        #expect(result.items.contains { $0.name == "Bench Press" })
        #expect(result.items.contains { $0.name == "Squat" })
    }

    @Test("Fetch exercises caches results")
    func testFetchExercisesCachesResults() async throws {
        let apiService = MockExerciseAPIService()
        let coreDataManager = CoreDataTestHelper.createInMemoryManager()

        await apiService.setExercises([
            .sample(id: "cache-test", name: "Cached Exercise")
        ])

        let repository = ExerciseRepository(
            apiService: apiService,
            coreDataManager: coreDataManager
        )

        // Fetch from API
        _ = try await repository.fetchExercises(filter: nil, page: 1, forceRefresh: true)

        // Verify cached
        let cached = repository.getCachedExercises(filter: nil)
        #expect(cached.count == 1)
        #expect(cached.first?.name == "Cached Exercise")
    }

    @Test("Fetch exercises falls back to cache on network failure")
    func testFetchExercisesFallsBackToCacheOnNetworkFailure() async throws {
        let apiService = MockExerciseAPIService()
        let coreDataManager = CoreDataTestHelper.createInMemoryManager()

        // Pre-populate cache
        let cachedExercise = CoreDataTestHelper.createSampleExerciseLibraryItem(
            serverId: "cached",
            name: "Cached Only"
        )
        try await coreDataManager.cacheExercises([cachedExercise])

        // Set API to fail
        await apiService.setShouldFail(true)

        let repository = ExerciseRepository(
            apiService: apiService,
            coreDataManager: coreDataManager
        )

        let result = try await repository.fetchExercises(
            filter: nil,
            page: 1,
            forceRefresh: true
        )

        #expect(result.items.count == 1)
        #expect(result.items.first?.name == "Cached Only")
    }

    // MARK: - Fetch Single Exercise

    @Test("Fetch exercise by ID returns exercise from API")
    func testFetchExerciseByIdReturnsFromAPI() async throws {
        let apiService = MockExerciseAPIService()
        let coreDataManager = CoreDataTestHelper.createInMemoryManager()

        await apiService.setExercises([
            .sample(id: "specific-id", name: "Specific Exercise")
        ])

        let repository = ExerciseRepository(
            apiService: apiService,
            coreDataManager: coreDataManager
        )

        let exercise = try await repository.fetchExercise(
            serverId: "specific-id",
            forceRefresh: true
        )

        #expect(exercise.name == "Specific Exercise")
    }

    @Test("Fetch exercise returns cached when not forcing refresh")
    func testFetchExerciseReturnsCachedWhenNotForcingRefresh() async throws {
        let apiService = MockExerciseAPIService()
        let coreDataManager = CoreDataTestHelper.createInMemoryManager()

        // Pre-populate cache
        let cachedExercise = CoreDataTestHelper.createSampleExerciseLibraryItem(
            serverId: "cached-exercise",
            name: "From Cache"
        )
        try await coreDataManager.cacheExercises([cachedExercise])

        let repository = ExerciseRepository(
            apiService: apiService,
            coreDataManager: coreDataManager
        )

        let exercise = try await repository.fetchExercise(
            serverId: "cached-exercise",
            forceRefresh: false
        )

        #expect(exercise.name == "From Cache")
    }

    // MARK: - Search Exercises

    @Test("Search exercises returns matching results")
    func testSearchExercisesReturnsMatchingResults() async throws {
        let apiService = MockExerciseAPIService()
        let coreDataManager = CoreDataTestHelper.createInMemoryManager()

        await apiService.setExercises([
            .sample(id: "ex-1", name: "Bench Press"),
            .sample(id: "ex-2", name: "Incline Bench Press"),
            .sample(id: "ex-3", name: "Squat")
        ])

        let repository = ExerciseRepository(
            apiService: apiService,
            coreDataManager: coreDataManager
        )

        let results = try await repository.searchExercises(query: "bench", limit: 10)

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.name.lowercased().contains("bench") })
    }

    @Test("Search exercises falls back to local search on network failure")
    func testSearchExercisesFallsBackToLocalOnNetworkFailure() async throws {
        let apiService = MockExerciseAPIService()
        let coreDataManager = CoreDataTestHelper.createInMemoryManager()

        // Pre-populate cache
        let exercises = [
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-1", name: "Bench Press"),
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-2", name: "Squat")
        ]
        try await coreDataManager.cacheExercises(exercises)

        // Set API to fail
        await apiService.setShouldFail(true)

        let repository = ExerciseRepository(
            apiService: apiService,
            coreDataManager: coreDataManager
        )

        let results = try await repository.searchExercises(query: "bench", limit: 10)

        #expect(results.count == 1)
        #expect(results.first?.name == "Bench Press")
    }

    // MARK: - Popular Exercises

    @Test("Fetch popular exercises returns sorted by popularity")
    func testFetchPopularExercisesReturnsSortedByPopularity() async throws {
        let apiService = MockExerciseAPIService()
        let coreDataManager = CoreDataTestHelper.createInMemoryManager()

        await apiService.setExercises([
            ExerciseDTO(
                id: "low",
                name: "Low Popularity",
                primaryMuscles: ["chest"],
                secondaryMuscles: nil,
                equipment: nil,
                difficulty: nil,
                movementPattern: nil,
                exerciseType: nil,
                instructions: nil,
                videoUrl: nil,
                thumbnailUrl: nil,
                popularityScore: 10,
                createdAt: nil,
                updatedAt: nil
            ),
            ExerciseDTO(
                id: "high",
                name: "High Popularity",
                primaryMuscles: ["chest"],
                secondaryMuscles: nil,
                equipment: nil,
                difficulty: nil,
                movementPattern: nil,
                exerciseType: nil,
                instructions: nil,
                videoUrl: nil,
                thumbnailUrl: nil,
                popularityScore: 100,
                createdAt: nil,
                updatedAt: nil
            )
        ])

        let repository = ExerciseRepository(
            apiService: apiService,
            coreDataManager: coreDataManager
        )

        let popular = try await repository.fetchPopularExercises(limit: 10)

        #expect(popular.count == 2)
        #expect(popular.first?.name == "High Popularity")
    }

    // MARK: - Exercises by Muscle

    @Test("Fetch exercises by muscle returns correct exercises")
    func testFetchExercisesByMuscleReturnsCorrectExercises() async throws {
        let apiService = MockExerciseAPIService()
        let coreDataManager = CoreDataTestHelper.createInMemoryManager()

        await apiService.setExercises([
            .sample(id: "ex-1", name: "Bench Press", primaryMuscles: ["chest"]),
            .sample(id: "ex-2", name: "Lat Pulldown", primaryMuscles: ["back"])
        ])

        let repository = ExerciseRepository(
            apiService: apiService,
            coreDataManager: coreDataManager
        )

        let chestExercises = try await repository.fetchExercisesByMuscle(.chest, limit: 10)

        #expect(chestExercises.count == 1)
        #expect(chestExercises.first?.name == "Bench Press")
    }

    // MARK: - Cache Operations

    @Test("Get cached exercises returns cached items")
    func testGetCachedExercisesReturnsCachedItems() async throws {
        let apiService = MockExerciseAPIService()
        let coreDataManager = CoreDataTestHelper.createInMemoryManager()

        // Pre-populate cache
        let exercises = [
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-1"),
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-2")
        ]
        try await coreDataManager.cacheExercises(exercises)

        let repository = ExerciseRepository(
            apiService: apiService,
            coreDataManager: coreDataManager
        )

        let cached = repository.getCachedExercises(filter: nil)
        #expect(cached.count == 2)
    }

    @Test("Get cached exercise returns specific exercise")
    func testGetCachedExerciseReturnsSpecificExercise() async throws {
        let apiService = MockExerciseAPIService()
        let coreDataManager = CoreDataTestHelper.createInMemoryManager()

        let exercise = CoreDataTestHelper.createSampleExerciseLibraryItem(
            serverId: "specific",
            name: "Specific Exercise"
        )
        try await coreDataManager.cacheExercises([exercise])

        let repository = ExerciseRepository(
            apiService: apiService,
            coreDataManager: coreDataManager
        )

        let cached = repository.getCachedExercise(serverId: "specific")
        #expect(cached != nil)
        #expect(cached?.name == "Specific Exercise")
    }

    @Test("Clear cache removes all cached exercises")
    func testClearCacheRemovesAllCachedExercises() async throws {
        let apiService = MockExerciseAPIService()
        let coreDataManager = CoreDataTestHelper.createInMemoryManager()

        // Pre-populate cache
        let exercises = [
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-1"),
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-2")
        ]
        try await coreDataManager.cacheExercises(exercises)

        let repository = ExerciseRepository(
            apiService: apiService,
            coreDataManager: coreDataManager
        )

        // Verify cache has items
        let beforeClear = repository.getCachedExercises(filter: nil)
        #expect(beforeClear.count == 2)

        // Clear cache
        try await repository.clearCache()

        // Verify cache is empty
        let afterClear = repository.getCachedExercises(filter: nil)
        #expect(afterClear.count == 0)
    }
}
