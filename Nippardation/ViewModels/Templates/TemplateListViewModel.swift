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
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies

    private let templateRepository: any TemplateRepositoryProtocol
    private let taskManager = TaskManager()

    // MARK: - Initialization

    init(templateRepository: (any TemplateRepositoryProtocol)? = nil) {
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository
    }

    // MARK: - Public Methods

    /// Loads templates from the repository
    /// - Parameter refresh: If true, forces a refresh from the server
    func loadTemplates(refresh: Bool = false) {
        guard !isLoading else { return }

        Task {
            await taskManager.run(id: "loadTemplates") { [weak self] in
                guard let self = self else { return }

                await MainActor.run { self.isLoading = true }

                do {
                    let fetchedTemplates = try await self.templateRepository.fetchTemplates(forceRefresh: refresh)

                    await MainActor.run {
                        self.templates = fetchedTemplates
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

                    await MainActor.run { self.isLoading = true }

                    do {
                        let fetchedTemplates = try await self.templateRepository.fetchTemplates(forceRefresh: true)

                        await MainActor.run {
                            self.templates = fetchedTemplates
                            self.error = nil
                            self.isLoading = false
                        }
                    } catch {
                        await MainActor.run {
                            let cached = self.templateRepository.getCachedTemplates()
                            if !cached.isEmpty {
                                self.templates = cached
                            }
                            self.error = error.localizedDescription
                            self.isLoading = false
                        }
                    }

                    continuation.resume()
                }
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
                        self.templates.removeAll { $0.id == template.id }
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
