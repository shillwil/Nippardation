//
//  TemplateListViewModel.swift
//  Nippardation
//
//  ViewModel for managing the list of workout templates
//

import Foundation
import Combine

@MainActor
final class TemplateListViewModel: ObservableObject {

    // MARK: - Published State

    @Published var templates: [Template] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var error: String?

    /// Templates filtered by search text
    var filteredTemplates: [Template] {
        guard !searchText.isEmpty else { return templates }
        let query = searchText.lowercased()
        return templates.filter { $0.name.lowercased().contains(query) }
    }

    // MARK: - Dependencies

    private let templateRepository: any TemplateRepositoryProtocol
    private let taskManager = TaskManager()

    // MARK: - Initialization

    init(templateRepository: (any TemplateRepositoryProtocol)? = nil) {
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository
    }

    // MARK: - Public Methods

    /// Checks if the cache differs from our in-memory list and triggers a reload.
    /// Detects both additions (e.g., AI generation) and deletions (e.g., program delete with template cleanup).
    func loadIfStale() {
        let cached = templateRepository.getCachedTemplates()
        let currentIds = Set(templates.map(\.serverId))
        let cachedIds = Set(cached.map(\.serverId))

        if currentIds != cachedIds {
            loadTemplates(refresh: false)
        }
    }

    /// Loads templates from the repository
    /// - Parameter refresh: If true, forces a refresh from the server
    func loadTemplates(refresh: Bool = false) {
        guard !isLoading else { return }

        Task {
            await taskManager.run(id: "loadTemplates") { [weak self] in
                guard let self = self else { return }
                await self.performLoad(forceRefresh: refresh)
            }
        }
    }

    /// Refreshes templates (async version for pull-to-refresh)
    func refreshAsync() async {
        await withCheckedContinuation { continuation in
            Task {
                await taskManager.run(id: "loadTemplates") { [weak self] in
                    guard let self = self else {
                        continuation.resume()
                        return
                    }
                    await self.performLoad(forceRefresh: true)
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Private Methods

    /// Directly updates or inserts a template in the in-memory list.
    /// Use after a save so the list reflects the change without a full API refresh.
    func handleTemplateSaved(_ template: Template) {
        if let index = templates.firstIndex(where: { $0.serverId == template.serverId }) {
            templates[index] = template
        } else {
            templates.insert(template, at: 0)
        }
    }

    /// Core loading logic shared between loadTemplates and refreshAsync
    /// - Parameter forceRefresh: Whether to force refresh from network
    private func performLoad(forceRefresh: Bool) async {
        await MainActor.run { self.isLoading = true }

        do {
            let fetchedTemplates = try await templateRepository.fetchTemplates(forceRefresh: forceRefresh)

            await MainActor.run {
                // Preserve exercise data from existing in-memory templates when
                // the API list endpoint returns templates without exercises.
                if !self.templates.isEmpty {
                    let existingByServerId = Dictionary(
                        self.templates.map { ($0.serverId, $0) },
                        uniquingKeysWith: { first, _ in first }
                    )
                    self.templates = fetchedTemplates.map { template in
                        guard template.exercises.isEmpty,
                              let existing = existingByServerId[template.serverId] else {
                            return template
                        }
                        var merged = template
                        if !existing.exercises.isEmpty {
                            merged.exercises = existing.exercises
                        } else if merged._knownExerciseCount == nil, let count = existing._knownExerciseCount {
                            merged._knownExerciseCount = count
                        }
                        return merged
                    }
                } else {
                    self.templates = fetchedTemplates
                }
                self.error = nil
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                // Try loading from cache on failure
                let cached = self.templateRepository.getCachedTemplates()
                if !cached.isEmpty {
                    self.templates = cached
                }
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    /// Deletes a template
    /// - Parameter template: The template to delete
    func deleteTemplate(_ template: Template) {
        Task {
            await taskManager.run(id: "delete-\(template.serverId)") { [weak self] in
                guard let self = self else { return }

                do {
                    try await self.templateRepository.deleteTemplate(serverId: template.serverId)

                    await MainActor.run {
                        self.templates.removeAll { $0.serverId == template.serverId }
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to delete template: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Duplicates a template
    /// - Parameter template: The template to duplicate
    func duplicateTemplate(_ template: Template) {
        Task {
            await taskManager.run(id: "duplicate-\(template.serverId)") { [weak self] in
                guard let self = self else { return }

                do {
                    let duplicate = try await self.templateRepository.duplicateTemplate(
                        serverId: template.serverId
                    )

                    await MainActor.run {
                        self.templates.insert(duplicate, at: 0)
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to duplicate template: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Clears the current error message
    func clearError() {
        error = nil
    }
}
