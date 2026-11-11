//
//  ProgramRepositoryTests.swift
//  NippardationTests
//
//  Tests for ProgramRepository
//

import Testing
import Foundation
@testable import Nippardation

@Suite("ProgramRepository Tests")
@MainActor
struct ProgramRepositoryTests {

    // MARK: - Helpers

    /// `Nippardation.`-qualified: the test target declares its own `MockProgramAPIService`
    /// actor, which records nothing — this is the app-target class. It starts out holding
    /// "prog_002", a four-day plan.
    private func makeAPI() -> Nippardation.MockProgramAPIService {
        let api = Nippardation.MockProgramAPIService()
        api.fetchDelay = 0
        return api
    }

    private func day(_ number: Int, _ templateId: String) -> ProgramWorkout {
        CoreDataTestHelper.createSampleProgramWorkout(
            serverId: "",
            dayNumber: number,
            templateServerId: templateId
        )
    }

    /// The mock server's "prog_002" plan with the rotation the editor is about to save.
    private func plan(days: [ProgramWorkout]) -> Program {
        var program = CoreDataTestHelper.createSampleProgram(
            serverId: "prog_002",
            name: "Upper Lower",
            daysPerWeek: days.count
        )
        program.workouts = days
        return program
    }

    // MARK: - Update

    @Test("Removing a day sends the day count and the rotation in one request")
    func testUpdateProgramSendsOneCombinedRequestWhenRemovingADay() async throws {
        let api = makeAPI()
        let repository = ProgramRepository(
            apiService: api,
            coreDataManager: CoreDataTestHelper.createInMemoryManager()
        )

        // The server holds four days. The user deleted one and saves the three that are left.
        let updated = try await repository.updateProgram(
            plan(days: [day(0, "tmpl_001"), day(1, "tmpl_003"), day(2, "tmpl_002")])
        )

        #expect(api.updateProgramCallCount == 1)
        #expect(api.updateProgramWorkoutsCallCount == 0)
        #expect(api.lastUpdateRequest?.name == "Upper Lower")
        #expect(api.lastUpdateRequest?.daysPerWeek == 3)
        #expect(api.lastUpdateRequest?.workouts?.map(\.dayNumber) == [0, 1, 2])
        #expect(api.lastUpdateRequest?.workouts?.map(\.templateId) == ["tmpl_001", "tmpl_003", "tmpl_002"])

        #expect(updated.serverId == "prog_002")
        #expect(updated.daysPerWeek == 3)
        #expect(updated.workouts.map(\.dayNumber) == [0, 1, 2])
        #expect(updated.workouts.map(\.templateServerId) == ["tmpl_001", "tmpl_003", "tmpl_002"])
    }

    @Test("Adding a day sends the day count and the rotation in one request")
    func testUpdateProgramSendsOneCombinedRequestWhenAddingADay() async throws {
        let api = makeAPI()
        let repository = ProgramRepository(
            apiService: api,
            coreDataManager: CoreDataTestHelper.createInMemoryManager()
        )

        let updated = try await repository.updateProgram(
            plan(days: [
                day(0, "tmpl_001"), day(1, "tmpl_003"), day(2, "tmpl_002"),
                day(3, "tmpl_003"), day(4, "tmpl_001")
            ])
        )

        #expect(api.updateProgramCallCount == 1)
        #expect(api.updateProgramWorkoutsCallCount == 0)
        #expect(api.lastUpdateRequest?.daysPerWeek == 5)
        #expect(api.lastUpdateRequest?.workouts?.map(\.dayNumber) == [0, 1, 2, 3, 4])
        #expect(updated.daysPerWeek == 5)
        #expect(updated.workouts.count == 5)
    }

    @Test("Removing a day replaces the cached rotation")
    func testUpdateProgramReplacesCachedRotationWhenRemovingADay() async throws {
        let api = makeAPI()
        let manager = CoreDataTestHelper.createInMemoryManager()
        let repository = ProgramRepository(apiService: api, coreDataManager: manager)

        try await manager.cacheProgram(
            plan(days: [day(0, "tmpl_001"), day(1, "tmpl_003"), day(2, "tmpl_002"), day(3, "tmpl_003")])
        )

        _ = try await repository.updateProgram(
            plan(days: [day(0, "tmpl_001"), day(1, "tmpl_003"), day(2, "tmpl_002")])
        )

        guard let cached = repository.getCachedProgram(serverId: "prog_002") else {
            Issue.record("Updated program was not cached")
            return
        }

        #expect(cached.daysPerWeek == 3)
        #expect(cached.workouts.map(\.dayNumber) == [0, 1, 2])
        #expect(cached.workouts.map(\.templateServerId) == ["tmpl_001", "tmpl_003", "tmpl_002"])
    }

    @Test("A program whose rotation is not loaded sends metadata only")
    func testUpdateProgramSendsNeitherRotationNorDayCountWithoutWorkouts() async throws {
        let api = makeAPI()
        let repository = ProgramRepository(
            apiService: api,
            coreDataManager: CoreDataTestHelper.createInMemoryManager()
        )

        let updated = try await repository.updateProgram(plan(days: []))

        #expect(api.updateProgramCallCount == 1)
        #expect(api.updateProgramWorkoutsCallCount == 0)
        #expect(api.lastUpdateRequest?.name == "Upper Lower")

        // Without the rotation in hand the request must not change the day count either,
        // or the server would shorten a rotation this device never loaded.
        #expect(api.lastUpdateRequest?.daysPerWeek == nil)
        #expect(api.lastUpdateRequest?.workouts?.count == nil)

        // The server's four days are untouched.
        #expect(updated.daysPerWeek == 4)
        #expect(updated.workouts.count == 4)
    }

    @Test("A saved active plan is what the next active-plan fetch returns")
    func testUpdateProgramOfTheActivePlanSurvivesAReload() async throws {
        let api = makeAPI()
        let manager = CoreDataTestHelper.createInMemoryManager()
        let repository = ProgramRepository(apiService: api, coreDataManager: manager)

        // "prog_001" is the mock server's active plan, six days long. Save it with two.
        var program = CoreDataTestHelper.createSampleProgram(
            serverId: "prog_001",
            name: "Push Pull",
            daysPerWeek: 2
        )
        program.workouts = [day(0, "tmpl_001"), day(1, "tmpl_002")]
        _ = try await repository.updateProgram(program)

        // What the Plan screen does after a save: reload the active plan.
        guard let active = try await repository.getActiveProgram() else {
            Issue.record("No active program after the save")
            return
        }

        #expect(active.serverId == "prog_001")
        #expect(active.name == "Push Pull")
        #expect(active.daysPerWeek == 2)
        #expect(active.workouts.map(\.templateServerId) == ["tmpl_001", "tmpl_002"])

        // The reload must not put the old six days back in the cache.
        #expect(repository.getCachedProgram(serverId: "prog_001")?.workouts.count == 2)
    }

    @Test("A rotation the server refuses throws and leaves the cache alone")
    func testUpdateProgramThrowsWithoutCachingWhenTheRotationDoesNotFit() async throws {
        let api = makeAPI()
        let manager = CoreDataTestHelper.createInMemoryManager()
        let repository = ProgramRepository(apiService: api, coreDataManager: manager)

        // Three days, but the last one is numbered 3: outside a three-day rotation (0...2).
        let misnumbered = plan(days: [day(0, "tmpl_001"), day(1, "tmpl_003"), day(3, "tmpl_002")])

        do {
            _ = try await repository.updateProgram(misnumbered)
            Issue.record("Expected updateProgram to throw")
        } catch {
            // Expected
        }

        #expect(api.updateProgramCallCount == 1)
        #expect(api.updateProgramWorkoutsCallCount == 0)
        #expect(manager.fetchCachedPrograms().isEmpty)

        // The server still holds its four days.
        let stored = try await api.fetchProgram(id: "prog_002")
        #expect(stored.daysPerWeek == 4)
        #expect(stored.workouts?.count == 4)
    }

    @Test("A failed update throws and leaves the cache alone")
    func testUpdateProgramThrowsWithoutCachingWhenTheRequestFails() async throws {
        let api = makeAPI()
        api.shouldThrowError = true
        let manager = CoreDataTestHelper.createInMemoryManager()
        let repository = ProgramRepository(apiService: api, coreDataManager: manager)

        do {
            _ = try await repository.updateProgram(
                plan(days: [day(0, "tmpl_001"), day(1, "tmpl_003"), day(2, "tmpl_002")])
            )
            Issue.record("Expected updateProgram to throw")
        } catch {
            // Expected
        }

        #expect(api.updateProgramCallCount == 1)
        #expect(api.updateProgramWorkoutsCallCount == 0)
        #expect(manager.fetchCachedPrograms().isEmpty)
    }
}
