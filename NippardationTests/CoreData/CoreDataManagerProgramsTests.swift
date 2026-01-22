//
//  CoreDataManagerProgramsTests.swift
//  NippardationTests
//
//  Tests for CoreDataManager+Programs extension
//

import Testing
import Foundation
import CoreData
@testable import Nippardation

@Suite("CoreDataManager+Programs Tests")
struct CoreDataManagerProgramsTests {

    // MARK: - Cache Operations

    @Test("Cache program saves to Core Data")
    func testCacheProgramSavesToCoreData() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let program = CoreDataTestHelper.createSampleProgram(
            serverId: "program-1",
            name: "PPL Program"
        )

        try await manager.cacheProgram(program)

        let cached = manager.fetchCachedPrograms()
        #expect(cached.count == 1)
        #expect(cached.first?.name == "PPL Program")
    }

    @Test("Cache program with workouts preserves relationships")
    func testCacheProgramWithWorkoutsPreservesRelationships() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let workouts = [
            CoreDataTestHelper.createSampleProgramWorkout(serverId: "pw-1", dayNumber: 1),
            CoreDataTestHelper.createSampleProgramWorkout(serverId: "pw-2", dayNumber: 2),
            CoreDataTestHelper.createSampleProgramWorkout(serverId: "pw-3", dayNumber: 3)
        ]

        let program = Program(
            id: UUID(),
            serverId: "program-with-workouts",
            name: "Full Program",
            description: "Complete program",
            daysPerWeek: 3,
            durationWeeks: 8,
            workouts: workouts,
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )

        try await manager.cacheProgram(program)

        guard let cached = manager.fetchCachedProgram(serverId: "program-with-workouts") else {
            Issue.record("Failed to fetch cached program")
            return
        }

        #expect(cached.workoutsArray.count == 3)
        #expect(cached.workoutsArray[0].dayNumber == 1)
        #expect(cached.workoutsArray[1].dayNumber == 2)
        #expect(cached.workoutsArray[2].dayNumber == 3)
    }

    @Test("Cache program updates existing program")
    func testCacheProgramUpdatesExisting() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        // Cache initial version
        let initial = CoreDataTestHelper.createSampleProgram(
            serverId: "program-update",
            name: "Original Name",
            daysPerWeek: 3
        )
        try await manager.cacheProgram(initial)

        // Cache updated version
        let updated = Program(
            id: UUID(),
            serverId: "program-update",
            name: "Updated Name",
            description: nil,
            daysPerWeek: 5,
            durationWeeks: nil,
            workouts: [],
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
        try await manager.cacheProgram(updated)

        let cached = manager.fetchCachedPrograms()
        #expect(cached.count == 1)
        #expect(cached.first?.name == "Updated Name")
        #expect(cached.first?.daysPerWeek == 5)
    }

    // MARK: - Active Program

    @Test("Set active program deactivates other programs")
    func testSetActiveProgramDeactivatesOthers() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        // Create two programs
        let program1 = CoreDataTestHelper.createSampleProgram(
            serverId: "program-1",
            name: "Program 1",
            isActive: true
        )
        let program2 = CoreDataTestHelper.createSampleProgram(
            serverId: "program-2",
            name: "Program 2",
            isActive: false
        )

        try await manager.cacheProgram(program1)
        try await manager.cacheProgram(program2)

        // Set program 2 as active
        try await manager.setActiveProgram(serverId: "program-2")

        // Verify program 1 is deactivated
        let cached1 = manager.fetchCachedProgram(serverId: "program-1")
        #expect(cached1?.isActive == false)

        // Verify program 2 is active
        let cached2 = manager.fetchCachedProgram(serverId: "program-2")
        #expect(cached2?.isActive == true)
    }

    @Test("Fetch active program returns only active program")
    func testFetchActiveProgramReturnsOnlyActive() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let inactive = CoreDataTestHelper.createSampleProgram(
            serverId: "inactive",
            name: "Inactive",
            isActive: false
        )
        let active = CoreDataTestHelper.createSampleProgram(
            serverId: "active",
            name: "Active",
            isActive: true
        )

        try await manager.cacheProgram(inactive)
        try await manager.cacheProgram(active)

        let fetched = manager.fetchCachedActiveProgram()
        #expect(fetched != nil)
        #expect(fetched?.name == "Active")
    }

    @Test("Fetch active program returns nil when none active")
    func testFetchActiveProgramReturnsNilWhenNoneActive() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let program = CoreDataTestHelper.createSampleProgram(
            serverId: "inactive",
            isActive: false
        )
        try await manager.cacheProgram(program)

        let fetched = manager.fetchCachedActiveProgram()
        #expect(fetched == nil)
    }

    @Test("Deactivate program sets isActive to false")
    func testDeactivateProgramSetsIsActiveFalse() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let program = CoreDataTestHelper.createSampleProgram(
            serverId: "to-deactivate",
            isActive: true
        )
        try await manager.cacheProgram(program)

        try await manager.deactivateProgram(serverId: "to-deactivate")

        let cached = manager.fetchCachedProgram(serverId: "to-deactivate")
        #expect(cached?.isActive == false)
    }

    // MARK: - Progress Updates

    @Test("Update program progress updates currentDayIndex and timesCompleted")
    func testUpdateProgramProgressUpdatesFields() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let program = CoreDataTestHelper.createSampleProgram(serverId: "progress-test")
        try await manager.cacheProgram(program)

        try await manager.updateProgramProgress(
            serverId: "progress-test",
            currentDayIndex: 3,
            timesCompleted: 2
        )

        guard let cached = manager.fetchCachedProgram(serverId: "progress-test") else {
            Issue.record("Failed to fetch cached program")
            return
        }

        #expect(cached.currentDayIndex == 3)
        #expect(cached.timesCompleted == 2)
    }

    // MARK: - Fetch Operations

    @Test("Fetch cached program by server ID")
    func testFetchCachedProgramByServerId() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let program = CoreDataTestHelper.createSampleProgram(
            serverId: "specific-program",
            name: "Specific Program"
        )
        try await manager.cacheProgram(program)

        let fetched = manager.fetchCachedProgram(serverId: "specific-program")
        #expect(fetched != nil)
        #expect(fetched?.name == "Specific Program")
    }

    @Test("Fetch cached program returns nil for non-existent")
    func testFetchCachedProgramReturnsNilForNonExistent() {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let fetched = manager.fetchCachedProgram(serverId: "non-existent")
        #expect(fetched == nil)
    }

    @Test("Fetch programs returns sorted with active first")
    func testFetchProgramsReturnsSortedWithActiveFirst() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let inactive = CoreDataTestHelper.createSampleProgram(
            serverId: "inactive",
            name: "Inactive",
            isActive: false
        )
        let active = CoreDataTestHelper.createSampleProgram(
            serverId: "active",
            name: "Active",
            isActive: true
        )

        try await manager.cacheProgram(inactive)
        try await manager.cacheProgram(active)

        let cached = manager.fetchCachedPrograms()
        #expect(cached.count == 2)
        #expect(cached.first?.isActive == true)
    }

    // MARK: - Pending Programs

    @Test("Fetch pending programs returns unsynced programs")
    func testFetchPendingProgramsReturnsUnsynced() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let unsynced = Program(
            id: UUID(),
            serverId: "",
            name: "Unsynced",
            description: nil,
            daysPerWeek: 3,
            durationWeeks: nil,
            workouts: [],
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
        try await manager.cacheProgram(unsynced)

        let pending = manager.fetchPendingPrograms()
        #expect(pending.count >= 1)
    }

    // MARK: - Delete Operations

    @Test("Delete cached program removes from Core Data")
    func testDeleteCachedProgramRemoves() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let program = CoreDataTestHelper.createSampleProgram(
            serverId: "delete-me"
        )
        try await manager.cacheProgram(program)

        // Verify exists
        let beforeDelete = manager.fetchCachedProgram(serverId: "delete-me")
        #expect(beforeDelete != nil)

        // Delete
        try await manager.deleteCachedProgram(serverId: "delete-me")

        // Verify removed
        let afterDelete = manager.fetchCachedProgram(serverId: "delete-me")
        #expect(afterDelete == nil)
    }

    @Test("Clear program cache removes all programs")
    func testClearProgramCacheRemovesAll() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let programs = [
            CoreDataTestHelper.createSampleProgram(serverId: "p-1"),
            CoreDataTestHelper.createSampleProgram(serverId: "p-2")
        ]
        for program in programs {
            try await manager.cacheProgram(program)
        }

        // Verify exist
        let before = manager.fetchCachedPrograms()
        #expect(before.count == 2)

        // Clear
        try await manager.clearProgramCache()

        // Verify removed
        let after = manager.fetchCachedPrograms()
        #expect(after.count == 0)
    }

    // MARK: - Domain Conversion

    @Test("toDomain converts CDProgram correctly")
    func testToDomainConvertsProgramCorrectly() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let program = Program(
            id: UUID(),
            serverId: "convert-program",
            name: "Conversion Test",
            description: "Test description",
            daysPerWeek: 4,
            durationWeeks: 12,
            workouts: [
                CoreDataTestHelper.createSampleProgramWorkout(dayNumber: 1)
            ],
            isActive: true,
            currentDayIndex: 2,
            timesCompleted: 3,
            isPublic: true,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
        try await manager.cacheProgram(program)

        guard let cdProgram = manager.fetchCachedProgram(serverId: "convert-program") else {
            Issue.record("Failed to fetch cached program")
            return
        }

        let converted = manager.toDomain(cdProgram)

        #expect(converted.serverId == "convert-program")
        #expect(converted.name == "Conversion Test")
        #expect(converted.description == "Test description")
        #expect(converted.daysPerWeek == 4)
        #expect(converted.durationWeeks == 12)
        #expect(converted.isActive == true)
        #expect(converted.currentDayIndex == 2)
        #expect(converted.timesCompleted == 3)
        #expect(converted.isPublic == true)
        #expect(converted.workouts.count == 1)
    }

    @Test("toDomain converts ProgramWorkout correctly")
    func testToDomainConvertsProgramWorkoutCorrectly() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let workout = ProgramWorkout(
            id: UUID(),
            serverId: "pw-convert",
            dayNumber: 3,
            dayLabel: "Pull Day",
            templateServerId: "template-1",
            template: nil
        )

        let program = Program(
            id: UUID(),
            serverId: "pw-test",
            name: "PW Test",
            description: nil,
            daysPerWeek: 3,
            durationWeeks: nil,
            workouts: [workout],
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
        try await manager.cacheProgram(program)

        guard let cdProgram = manager.fetchCachedProgram(serverId: "pw-test"),
              let cdWorkout = cdProgram.workoutsArray.first else {
            Issue.record("Failed to fetch cached data")
            return
        }

        let converted = manager.toDomain(cdWorkout)

        #expect(converted.dayNumber == 3)
        #expect(converted.dayLabel == "Pull Day")
        #expect(converted.templateServerId == "template-1")
    }
}
