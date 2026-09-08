//
//  ExerciseLibraryResolverTests.swift
//  NippardationTests
//
//  The resolver that fills in exercise library items so real movement names show up
//  in plans that arrived from a list endpoint, a program payload, a share or the AI.
//

import Testing
import Foundation
@testable import Nippardation

@Suite("ExerciseLibraryResolver")
@MainActor
struct ExerciseLibraryResolverTests {

    // MARK: - Helpers

    /// Serial lookups so the mock's call counter is deterministic.
    /// `Nippardation.`-qualified: the test target declares its own `MockExerciseAPIService`
    /// actor, which has no call counter — this is the app-target class.
    private func makeResolver(
        _ manager: CoreDataManager,
        _ api: Nippardation.MockExerciseAPIService?
    ) -> ExerciseLibraryResolver {
        ExerciseLibraryResolver(
            coreDataManager: manager,
            exerciseAPIService: api,
            maxConcurrentLookups: 1
        )
    }

    private func makeAPI() -> Nippardation.MockExerciseAPIService {
        let api = Nippardation.MockExerciseAPIService()
        api.fetchDelay = 0
        return api
    }

    /// A template exercise the way a list endpoint delivers one: an id and nothing else.
    private func unresolved(_ exerciseServerId: String, order: Int = 0) -> TemplateExercise {
        TemplateExercise(
            id: UUID(),
            serverId: "te_\(order)",
            exerciseServerId: exerciseServerId,
            exerciseLibraryItem: nil,
            orderIndex: order,
            warmupSets: nil,
            workingSets: 3,
            targetReps: "8-12",
            restSeconds: 90,
            notes: nil
        )
    }

    /// The name-only item the AI mapper builds from a generation response.
    private func placeholder(_ name: String, serverId: String) -> ExerciseLibraryItem {
        ExerciseLibraryItem(
            id: UUID(),
            serverId: serverId,
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
            lastFetchedAt: nil,
            isPlaceholder: true
        )
    }

    private func placeholderExercise(_ name: String, serverId: String) -> TemplateExercise {
        var exercise = unresolved(serverId)
        exercise.exerciseLibraryItem = placeholder(name, serverId: serverId)
        return exercise
    }

    // MARK: - Cache

    @Test("Resolves from the exercise cache without touching the network")
    func resolvesFromCache() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()
        try await manager.cacheExercises([
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-1", name: "Bench Press")
        ])

        let resolved = await makeResolver(manager, api).resolve([unresolved("ex-1")])

        #expect(resolved.first?.displayName == "Bench Press")
        #expect(resolved.first?.hasResolvedName == true)
        #expect(api.fetchExerciseCallCount == 0)
    }

    @Test("Cache-only resolution never reaches the API")
    func cacheOnlyResolution() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()
        try await manager.cacheExercises([
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-1", name: "Bench Press")
        ])
        let resolver = makeResolver(manager, api)

        let resolved = resolver.resolveFromCache([unresolved("ex-1"), unresolved("ex_001", order: 1)])

        #expect(resolved[0].displayName == "Bench Press")
        #expect(resolved[1].hasResolvedName == false)
        #expect(api.fetchExerciseCallCount == 0)
    }

    // MARK: - API fallback

    @Test("Falls back to the exercise API and caches what it fetched")
    func fallsBackToAPI() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()

        let resolved = await makeResolver(manager, api).resolve([unresolved("ex_001")])

        #expect(resolved.first?.displayName == "Barbell Bench Press")
        #expect(api.fetchExerciseCallCount == 1)
        // Cached, so the next read costs nothing.
        #expect(manager.fetchCachedExercise(serverId: "ex_001")?.name == "Barbell Bench Press")
    }

    @Test("A second resolve of the same movement is served from the cache")
    func secondResolveHitsCache() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()
        let resolver = makeResolver(manager, api)

        _ = await resolver.resolve([unresolved("ex_001")])
        let resolved = await resolver.resolve([unresolved("ex_001")])

        #expect(resolved.first?.displayName == "Barbell Bench Press")
        #expect(api.fetchExerciseCallCount == 1)
    }

    @Test("An exercise with no library id is never looked up")
    func skipsEmptyIds() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()

        let resolved = await makeResolver(manager, api).resolve([unresolved("")])

        #expect(api.fetchExerciseCallCount == 0)
        #expect(resolved.first?.displayName == "Exercise")
        #expect(resolved.first?.hasResolvedName == false)
    }

    // MARK: - Deduplication

    @Test("A movement repeated across days costs one request")
    func dedupesAcrossAPlan() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()

        func day(_ name: String, _ serverId: String) -> Template {
            VoidFixtures.template(name, serverId: serverId, exercises: [
                unresolved("ex_001"),
                unresolved("ex_002", order: 1)
            ])
        }

        let program = VoidFixtures.program(workouts: [
            VoidFixtures.programWorkout(day: 0, label: "Push", template: day("Push", "t_push")),
            VoidFixtures.programWorkout(day: 1, label: "Pull", template: day("Pull", "t_pull")),
            VoidFixtures.programWorkout(day: 2, label: "Legs", template: day("Legs", "t_legs"))
        ])

        let resolved = await makeResolver(manager, api).resolve(program)

        // Six exercises, two distinct movements, two requests.
        #expect(api.fetchExerciseCallCount == 2)
        let names = resolved.workouts
            .compactMap { $0.template }
            .flatMap { $0.exercises }
            .map { $0.displayName }
        #expect(names.filter({ $0 == "Barbell Bench Press" }).count == 3)
        #expect(names.filter({ $0 == "Barbell Back Squat" }).count == 3)
    }

    @Test("A list of templates is resolved in one batch")
    func dedupesAcrossTemplates() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()

        let templates = [
            VoidFixtures.template("Push", serverId: "t_push", exercises: [unresolved("ex_001")]),
            VoidFixtures.template("Upper", serverId: "t_upper", exercises: [unresolved("ex_001")])
        ]

        let resolved = await makeResolver(manager, api).resolve(templates)

        #expect(api.fetchExerciseCallCount == 1)
        #expect(resolved.allSatisfy({ $0.exercises.first?.displayName == "Barbell Bench Press" }))
    }

    // MARK: - Failure

    @Test("A failed lookup degrades to the generic name instead of throwing")
    func failedLookupDegrades() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()
        api.shouldThrowError = true

        let resolved = await makeResolver(manager, api).resolve([unresolved("ex_001")])

        #expect(resolved.count == 1)
        #expect(resolved.first?.exerciseLibraryItem == nil)
        #expect(resolved.first?.hasResolvedName == false)
        #expect(resolved.first?.displayName == "Exercise")
    }

    @Test("A failed lookup is not retried on the next read")
    func failedLookupBacksOff() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()
        api.shouldThrowError = true
        let resolver = makeResolver(manager, api)

        _ = await resolver.resolve([unresolved("ex_001")])
        _ = await resolver.resolve([unresolved("ex_001")])

        #expect(api.fetchExerciseCallCount == 1)
    }

    @Test("With no exercise API at all, resolution is cache-only and still succeeds")
    func worksWithoutAnAPI() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        try await manager.cacheExercises([
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-1", name: "Bench Press")
        ])

        let resolved = await makeResolver(manager, nil)
            .resolve([unresolved("ex-1"), unresolved("ex_001", order: 1)])

        #expect(resolved[0].displayName == "Bench Press")
        #expect(resolved[1].displayName == "Exercise")
    }

    // MARK: - Placeholders (the AI path)

    @Test("A name-only placeholder is upgraded to the real library item")
    func upgradesPlaceholder() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()

        let resolved = await makeResolver(manager, api)
            .resolve([placeholderExercise("Bench", serverId: "ex_001")])

        #expect(resolved.first?.displayName == "Barbell Bench Press")
        #expect(resolved.first?.exerciseLibraryItem?.isPlaceholder == false)
        #expect(resolved.first?.exerciseLibraryItem?.videoUrl != nil)
    }

    @Test("An unresolvable placeholder keeps its name, and keeps it across a cache round trip")
    func keepsPlaceholderName() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()
        api.shouldThrowError = true
        let resolver = makeResolver(manager, api)

        let resolved = await resolver.resolve([placeholderExercise("Cable Fly", serverId: "ai-1")])
        #expect(resolved.first?.displayName == "Cable Fly")

        // The name is what survives a Core Data round trip, since CDTemplateExercise
        // only stores the exercise id.
        #expect(manager.fetchCachedExercise(serverId: "ai-1")?.name == "Cable Fly")
        let reread = await resolver.resolve([unresolved("ai-1")])
        #expect(reread.first?.displayName == "Cable Fly")
        #expect(reread.first?.exerciseLibraryItem?.isPlaceholder == true)
    }

    @Test("A placeholder never overwrites a real cached exercise")
    func placeholderNeverOverwritesRealEntry() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()
        api.shouldThrowError = true
        try await manager.cacheExercises([
            CoreDataTestHelper.createSampleExerciseLibraryItem(serverId: "ex-9", name: "Cable Fly")
        ])

        let resolved = await makeResolver(manager, api)
            .resolve([placeholderExercise("Made Up Name", serverId: "ex-9")])

        #expect(resolved.first?.displayName == "Cable Fly")
        #expect(api.fetchExerciseCallCount == 0)
        #expect(manager.fetchCachedExercise(serverId: "ex-9")?.name == "Cable Fly")
    }

    @Test("The AI mapper's exercises carry a name and are flagged as placeholders")
    func aiMapperProducesPlaceholders() throws {
        let program = AIGeneratedProgramMapper.toDomain(MockAIAPIService.sampleGenerateResponse.program)
        let exercises = program.workouts.compactMap { $0.template }.flatMap { $0.exercises }

        #expect(!exercises.isEmpty)
        #expect(exercises.allSatisfy({ $0.hasResolvedName }))
        #expect(exercises.allSatisfy({ $0.displayName != "Exercise" }))
        #expect(exercises.allSatisfy({ $0.exerciseLibraryItem?.isPlaceholder == true }))
    }

    // MARK: - Shares

    @Test("A shared plan's embedded workouts are hydrated")
    func resolvesASharedPlan() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()
        let api = makeAPI()

        let program = VoidFixtures.program(workouts: [
            VoidFixtures.programWorkout(
                day: 0,
                label: "Push",
                template: VoidFixtures.template("Push", serverId: "t_push", exercises: [unresolved("ex_001")])
            )
        ])
        let item = SharedItem(
            token: "abc",
            type: .program,
            sharedBy: SharedItem.SharedBy(handle: "jeff", displayName: "Jeff", avatarUrl: nil),
            sharedAt: Date(),
            template: nil,
            program: program
        )

        let resolved = await makeResolver(manager, api).resolve(item)

        #expect(resolved.program?.workouts.first?.template?.exercises.first?.displayName == "Barbell Bench Press")
    }
}
