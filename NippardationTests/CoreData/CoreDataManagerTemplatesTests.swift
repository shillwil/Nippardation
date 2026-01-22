//
//  CoreDataManagerTemplatesTests.swift
//  NippardationTests
//
//  Tests for CoreDataManager+Templates extension
//

import Testing
import Foundation
import CoreData
@testable import Nippardation

@Suite("CoreDataManager+Templates Tests")
struct CoreDataManagerTemplatesTests {

    // MARK: - Cache Operations

    @Test("Cache template saves to Core Data")
    func testCacheTemplateSavesToCoreData() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let template = CoreDataTestHelper.createSampleTemplate(
            serverId: "template-1",
            name: "Push Day"
        )

        try await manager.cacheTemplate(template)

        let cached = manager.fetchCachedTemplates()
        #expect(cached.count == 1)
        #expect(cached.first?.name == "Push Day")
    }

    @Test("Cache template with exercises preserves relationships")
    func testCacheTemplateWithExercisesPreservesRelationships() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let exercises = [
            CoreDataTestHelper.createSampleTemplateExercise(
                serverId: "te-1",
                exerciseServerId: "ex-1",
                orderIndex: 0
            ),
            CoreDataTestHelper.createSampleTemplateExercise(
                serverId: "te-2",
                exerciseServerId: "ex-2",
                orderIndex: 1
            )
        ]

        let template = Template(
            id: UUID(),
            serverId: "template-with-exercises",
            name: "Full Workout",
            description: "Complete workout template",
            exercises: exercises,
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )

        try await manager.cacheTemplate(template)

        guard let cached = manager.fetchCachedTemplate(serverId: "template-with-exercises") else {
            Issue.record("Failed to fetch cached template")
            return
        }

        #expect(cached.exercisesArray.count == 2)
        #expect(cached.exercisesArray[0].orderIndex == 0)
        #expect(cached.exercisesArray[1].orderIndex == 1)
    }

    @Test("Cache template updates existing template")
    func testCacheTemplateUpdatesExisting() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        // Cache initial version
        let initial = CoreDataTestHelper.createSampleTemplate(
            serverId: "template-update",
            name: "Original Name"
        )
        try await manager.cacheTemplate(initial)

        // Cache updated version
        let updated = Template(
            id: UUID(),
            serverId: "template-update",
            name: "Updated Name",
            description: "Updated description",
            exercises: [],
            isPublic: true,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
        try await manager.cacheTemplate(updated)

        let cached = manager.fetchCachedTemplates()
        #expect(cached.count == 1)
        #expect(cached.first?.name == "Updated Name")
        #expect(cached.first?.isPublic == true)
    }

    @Test("Cache multiple templates")
    func testCacheMultipleTemplates() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let templates = [
            CoreDataTestHelper.createSampleTemplate(serverId: "t-1", name: "Push"),
            CoreDataTestHelper.createSampleTemplate(serverId: "t-2", name: "Pull"),
            CoreDataTestHelper.createSampleTemplate(serverId: "t-3", name: "Legs")
        ]

        try await manager.cacheTemplates(templates)

        let cached = manager.fetchCachedTemplates()
        #expect(cached.count == 3)
    }

    // MARK: - Fetch Operations

    @Test("Fetch cached template by server ID")
    func testFetchCachedTemplateByServerId() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let template = CoreDataTestHelper.createSampleTemplate(
            serverId: "specific-template",
            name: "Specific Template"
        )
        try await manager.cacheTemplate(template)

        let fetched = manager.fetchCachedTemplate(serverId: "specific-template")
        #expect(fetched != nil)
        #expect(fetched?.name == "Specific Template")
    }

    @Test("Fetch cached template returns nil for non-existent")
    func testFetchCachedTemplateReturnsNilForNonExistent() {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let fetched = manager.fetchCachedTemplate(serverId: "non-existent")
        #expect(fetched == nil)
    }

    @Test("Fetch templates returns sorted by updatedAt")
    func testFetchTemplatesReturnsSortedByUpdatedAt() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let oldDate = Date().addingTimeInterval(-86400) // 1 day ago
        let newDate = Date()

        let old = Template(
            id: UUID(),
            serverId: "old-template",
            name: "Old Template",
            description: nil,
            exercises: [],
            isPublic: false,
            isAiGenerated: false,
            createdAt: oldDate,
            updatedAt: oldDate,
            lastFetchedAt: nil
        )

        let new = Template(
            id: UUID(),
            serverId: "new-template",
            name: "New Template",
            description: nil,
            exercises: [],
            isPublic: false,
            isAiGenerated: false,
            createdAt: newDate,
            updatedAt: newDate,
            lastFetchedAt: nil
        )

        try await manager.cacheTemplate(old)
        try await manager.cacheTemplate(new)

        let cached = manager.fetchCachedTemplates()
        #expect(cached.count == 2)
        // Should be sorted descending by updatedAt
        #expect(cached.first?.name == "New Template")
    }

    // MARK: - Pending Templates

    @Test("Fetch pending templates returns unsynced templates")
    func testFetchPendingTemplatesReturnsUnsynced() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        // Create a template with empty serverId (unsynced)
        let unsynced = Template(
            id: UUID(),
            serverId: "",
            name: "Unsynced Template",
            description: nil,
            exercises: [],
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
        try await manager.cacheTemplate(unsynced)

        let pending = manager.fetchPendingTemplates()
        #expect(pending.count >= 1)
    }

    // MARK: - Delete Operations

    @Test("Delete cached template removes from Core Data")
    func testDeleteCachedTemplateRemoves() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let template = CoreDataTestHelper.createSampleTemplate(
            serverId: "delete-me",
            name: "To Delete"
        )
        try await manager.cacheTemplate(template)

        // Verify exists
        let beforeDelete = manager.fetchCachedTemplate(serverId: "delete-me")
        #expect(beforeDelete != nil)

        // Delete
        try await manager.deleteCachedTemplate(serverId: "delete-me")

        // Verify removed
        let afterDelete = manager.fetchCachedTemplate(serverId: "delete-me")
        #expect(afterDelete == nil)
    }

    @Test("Clear template cache removes all templates")
    func testClearTemplateCacheRemovesAll() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let templates = [
            CoreDataTestHelper.createSampleTemplate(serverId: "t-1"),
            CoreDataTestHelper.createSampleTemplate(serverId: "t-2")
        ]
        try await manager.cacheTemplates(templates)

        // Verify exist
        let before = manager.fetchCachedTemplates()
        #expect(before.count == 2)

        // Clear
        try await manager.clearTemplateCache()

        // Verify removed
        let after = manager.fetchCachedTemplates()
        #expect(after.count == 0)
    }

    // MARK: - Sync Status

    @Test("Mark template synced updates sync status")
    func testMarkTemplateSyncedUpdatesStatus() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let template = Template(
            id: UUID(),
            serverId: "sync-test",
            name: "Sync Test",
            description: nil,
            exercises: [],
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
        try await manager.cacheTemplate(template)

        try await manager.markTemplateSynced(serverId: "sync-test")

        guard let cached = manager.fetchCachedTemplate(serverId: "sync-test") else {
            Issue.record("Failed to fetch template")
            return
        }

        #expect(cached.syncStatus == 2) // 2 = synced
    }

    // MARK: - Domain Conversion

    @Test("toDomain converts CDTemplate correctly")
    func testToDomainConvertsTemplateCorrectly() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let template = Template(
            id: UUID(),
            serverId: "convert-template",
            name: "Conversion Test",
            description: "Test description",
            exercises: [
                CoreDataTestHelper.createSampleTemplateExercise(orderIndex: 0)
            ],
            isPublic: true,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
        try await manager.cacheTemplate(template)

        guard let cdTemplate = manager.fetchCachedTemplate(serverId: "convert-template") else {
            Issue.record("Failed to fetch cached template")
            return
        }

        let converted = manager.toDomain(cdTemplate)

        #expect(converted.serverId == "convert-template")
        #expect(converted.name == "Conversion Test")
        #expect(converted.description == "Test description")
        #expect(converted.isPublic == true)
        #expect(converted.exercises.count == 1)
    }

    @Test("toDomain converts TemplateExercise correctly")
    func testToDomainConvertsTemplateExerciseCorrectly() async throws {
        let manager = CoreDataTestHelper.createInMemoryManager()

        let templateExercise = TemplateExercise(
            id: UUID(),
            serverId: "te-convert",
            exerciseServerId: "ex-1",
            exerciseLibraryItem: nil,
            orderIndex: 2,
            warmupSets: 3,
            workingSets: 4,
            targetReps: "10-12",
            restSeconds: 120,
            notes: "Focus on form"
        )

        let template = Template(
            id: UUID(),
            serverId: "te-test",
            name: "TE Test",
            description: nil,
            exercises: [templateExercise],
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
        try await manager.cacheTemplate(template)

        guard let cdTemplate = manager.fetchCachedTemplate(serverId: "te-test"),
              let cdExercise = cdTemplate.exercisesArray.first else {
            Issue.record("Failed to fetch cached data")
            return
        }

        let converted = manager.toDomain(cdExercise)

        #expect(converted.orderIndex == 2)
        #expect(converted.warmupSets == 3)
        #expect(converted.workingSets == 4)
        #expect(converted.targetReps == "10-12")
        #expect(converted.restSeconds == 120)
        #expect(converted.notes == "Focus on form")
    }
}
