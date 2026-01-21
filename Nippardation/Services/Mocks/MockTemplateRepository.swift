//
//  MockTemplateRepository.swift
//  Nippardation
//
//  Phase 0: Mock implementation of TemplateRepositoryProtocol for testing and previews
//

import Foundation

/// Mock implementation of TemplateRepositoryProtocol
/// Provides sample data for testing and SwiftUI previews
@MainActor
final class MockTemplateRepository: TemplateRepositoryProtocol {

    // MARK: - Mock Data Storage

    private var templates: [Template] = MockTemplateRepository.sampleTemplates
    private var pendingTemplates: Set<String> = []
    private var shouldFail = false
    private var delay: TimeInterval = 0

    // MARK: - Configuration

    func setFailure(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }

    // MARK: - TemplateRepositoryProtocol

    func fetchTemplates(forceRefresh: Bool) async throws -> [Template] {
        try await simulateNetworkCall()
        return templates
    }

    func fetchTemplate(serverId: String, forceRefresh: Bool) async throws -> Template {
        try await simulateNetworkCall()
        guard let template = templates.first(where: { $0.serverId == serverId }) else {
            throw RepositoryError.notFound
        }
        return template
    }

    func fetchPublicTemplates(page: Int, category: String?) async throws -> PaginatedResult<Template> {
        try await simulateNetworkCall()
        let publicTemplates = templates.filter { $0.isPublic }
        return PaginatedResult(
            items: publicTemplates,
            page: 1,
            totalPages: 1,
            totalItems: publicTemplates.count
        )
    }

    func createTemplate(_ template: Template) async throws -> Template {
        try await simulateNetworkCall()
        var newTemplate = template
        newTemplate = Template(
            id: template.id,
            serverId: "tmpl_\(UUID().uuidString.prefix(8))",
            name: template.name,
            description: template.description,
            exercises: template.exercises,
            isPublic: template.isPublic,
            isAiGenerated: template.isAiGenerated,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: Date()
        )
        templates.append(newTemplate)
        return newTemplate
    }

    func updateTemplate(_ template: Template) async throws -> Template {
        try await simulateNetworkCall()
        guard let index = templates.firstIndex(where: { $0.serverId == template.serverId }) else {
            throw RepositoryError.notFound
        }
        templates[index] = template
        return template
    }

    func deleteTemplate(serverId: String) async throws {
        try await simulateNetworkCall()
        templates.removeAll { $0.serverId == serverId }
    }

    func duplicateTemplate(serverId: String) async throws -> Template {
        try await simulateNetworkCall()
        guard let original = templates.first(where: { $0.serverId == serverId }) else {
            throw RepositoryError.notFound
        }
        let duplicate = Template(
            id: UUID(),
            serverId: "tmpl_\(UUID().uuidString.prefix(8))",
            name: "\(original.name) (Copy)",
            description: original.description,
            exercises: original.exercises,
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: Date()
        )
        templates.append(duplicate)
        return duplicate
    }

    func getCachedTemplates() -> [Template] {
        templates
    }

    func getCachedTemplate(serverId: String) -> Template? {
        templates.first { $0.serverId == serverId }
    }

    func cacheTemplate(_ template: Template) async throws {
        if !templates.contains(where: { $0.id == template.id }) {
            templates.append(template)
        }
    }

    func clearCache() async throws {
        templates = MockTemplateRepository.sampleTemplates
    }

    func getPendingTemplates() -> [Template] {
        templates.filter { pendingTemplates.contains($0.serverId) }
    }

    func markTemplateSynced(serverId: String) async throws {
        pendingTemplates.remove(serverId)
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

extension MockTemplateRepository {

    static var sampleTemplates: [Template] {
        [
            Template(
                id: UUID(),
                serverId: "tmpl_001",
                name: "Push Day",
                description: "Chest, shoulders, and triceps focused workout",
                exercises: samplePushExercises,
                isPublic: false,
                isAiGenerated: false,
                createdAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date().addingTimeInterval(-86400),
                lastFetchedAt: Date()
            ),
            Template(
                id: UUID(),
                serverId: "tmpl_002",
                name: "Pull Day",
                description: "Back and biceps focused workout",
                exercises: samplePullExercises,
                isPublic: false,
                isAiGenerated: false,
                createdAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date().addingTimeInterval(-86400),
                lastFetchedAt: Date()
            ),
            Template(
                id: UUID(),
                serverId: "tmpl_003",
                name: "Leg Day",
                description: "Complete lower body workout",
                exercises: sampleLegExercises,
                isPublic: false,
                isAiGenerated: false,
                createdAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date().addingTimeInterval(-86400),
                lastFetchedAt: Date()
            )
        ]
    }

    static var samplePushExercises: [TemplateExercise] {
        [
            TemplateExercise(
                id: UUID(),
                serverId: "te_001",
                exerciseServerId: "ex_001",
                exerciseLibraryItem: MockExerciseRepository.sampleExercises.first { $0.serverId == "ex_001" },
                orderIndex: 0,
                warmupSets: 2,
                workingSets: 4,
                targetReps: "6-8",
                restSeconds: 180,
                notes: "Focus on controlled descent"
            ),
            TemplateExercise(
                id: UUID(),
                serverId: "te_002",
                exerciseServerId: "ex_005",
                exerciseLibraryItem: MockExerciseRepository.sampleExercises.first { $0.serverId == "ex_005" },
                orderIndex: 1,
                warmupSets: 0,
                workingSets: 3,
                targetReps: "12-15",
                restSeconds: 90,
                notes: nil
            ),
            TemplateExercise(
                id: UUID(),
                serverId: "te_003",
                exerciseServerId: "ex_007",
                exerciseLibraryItem: MockExerciseRepository.sampleExercises.first { $0.serverId == "ex_007" },
                orderIndex: 2,
                warmupSets: 0,
                workingSets: 3,
                targetReps: "10-12",
                restSeconds: 60,
                notes: nil
            )
        ]
    }

    static var samplePullExercises: [TemplateExercise] {
        [
            TemplateExercise(
                id: UUID(),
                serverId: "te_004",
                exerciseServerId: "ex_003",
                exerciseLibraryItem: MockExerciseRepository.sampleExercises.first { $0.serverId == "ex_003" },
                orderIndex: 0,
                warmupSets: 2,
                workingSets: 4,
                targetReps: "5",
                restSeconds: 180,
                notes: "Conventional stance"
            ),
            TemplateExercise(
                id: UUID(),
                serverId: "te_005",
                exerciseServerId: "ex_004",
                exerciseLibraryItem: MockExerciseRepository.sampleExercises.first { $0.serverId == "ex_004" },
                orderIndex: 1,
                warmupSets: 0,
                workingSets: 3,
                targetReps: "8-10",
                restSeconds: 120,
                notes: nil
            ),
            TemplateExercise(
                id: UUID(),
                serverId: "te_006",
                exerciseServerId: "ex_006",
                exerciseLibraryItem: MockExerciseRepository.sampleExercises.first { $0.serverId == "ex_006" },
                orderIndex: 2,
                warmupSets: 0,
                workingSets: 3,
                targetReps: "10-12",
                restSeconds: 60,
                notes: nil
            )
        ]
    }

    static var sampleLegExercises: [TemplateExercise] {
        [
            TemplateExercise(
                id: UUID(),
                serverId: "te_007",
                exerciseServerId: "ex_002",
                exerciseLibraryItem: MockExerciseRepository.sampleExercises.first { $0.serverId == "ex_002" },
                orderIndex: 0,
                warmupSets: 3,
                workingSets: 4,
                targetReps: "6-8",
                restSeconds: 180,
                notes: "High bar position"
            ),
            TemplateExercise(
                id: UUID(),
                serverId: "te_008",
                exerciseServerId: "ex_008",
                exerciseLibraryItem: MockExerciseRepository.sampleExercises.first { $0.serverId == "ex_008" },
                orderIndex: 1,
                warmupSets: 0,
                workingSets: 3,
                targetReps: "10-12",
                restSeconds: 120,
                notes: nil
            ),
            TemplateExercise(
                id: UUID(),
                serverId: "te_009",
                exerciseServerId: "ex_009",
                exerciseLibraryItem: MockExerciseRepository.sampleExercises.first { $0.serverId == "ex_009" },
                orderIndex: 2,
                warmupSets: 0,
                workingSets: 3,
                targetReps: "10-12",
                restSeconds: 90,
                notes: nil
            )
        ]
    }
}
