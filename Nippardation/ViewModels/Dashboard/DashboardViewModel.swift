//
//  DashboardViewModel.swift
//  Nippardation
//
//  ViewModel for the main dashboard showing active program and next workout
//

import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - Published State

    @Published var activeProgram: Program?
    @Published var nextWorkout: ProgramWorkout?
    @Published var nextTemplate: Template?
    @Published var allTemplates: [Template] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies

    private let programRepository: any ProgramRepositoryProtocol
    private let templateRepository: any TemplateRepositoryProtocol
    private let taskManager = TaskManager()

    // MARK: - Initialization

    init(
        programRepository: (any ProgramRepositoryProtocol)? = nil,
        templateRepository: (any TemplateRepositoryProtocol)? = nil
    ) {
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository
    }

    // MARK: - Public Methods

    /// Loads the dashboard data including active program and templates
    func loadDashboard() {
        Task {
            await taskManager.run(id: "loadDashboard") { [weak self] in
                guard let self = self else { return }
                await self.performLoad(forceRefresh: false)
            }
        }
    }

    /// Advances to the next workout in the active program
    func advanceToNextWorkout() {
        guard let program = activeProgram else { return }

        Task {
            await taskManager.run(id: "advance") { [weak self] in
                guard let self = self else { return }

                do {
                    let updated = try await self.programRepository.advanceToNextWorkout(
                        serverId: program.serverId
                    )

                    await MainActor.run {
                        self.activeProgram = updated
                        self.nextWorkout = updated.currentWorkout

                        // Update next template
                        if let currentWorkout = updated.currentWorkout {
                            self.nextTemplate = self.allTemplates.first {
                                $0.serverId == currentWorkout.templateServerId
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to advance: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Returns the template for a given workout
    /// - Parameter workout: The program workout
    /// - Returns: The associated template if found
    func templateFor(workout: ProgramWorkout) -> Template? {
        // Prefer detail-fetched templates (have exercises) over embedded summaries
        if let detailed = allTemplates.first(where: { $0.serverId == workout.templateServerId }) {
            return detailed
        }
        // Fall back to embedded summary template
        return workout.template
    }

    /// Refreshes the dashboard data (async version for pull-to-refresh)
    func refreshAsync() async {
        await withCheckedContinuation { continuation in
            Task {
                await taskManager.run(id: "loadDashboard") { [weak self] in
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

    /// Core loading logic shared between loadDashboard and refreshAsync
    /// - Parameter forceRefresh: Whether to force refresh from network
    private func performLoad(forceRefresh: Bool) async {
        await MainActor.run { self.isLoading = true }

        do {
            // Load active program
            let activeProgram = try await programRepository.getActiveProgram()

            var templatesBuilder: [Template] = []
            var nextTemplateFound: Template?

            if let program = activeProgram {
                // Load templates for the program
                for workout in program.workouts {
                    if let template = try? await templateRepository.fetchTemplate(
                        serverId: workout.templateServerId,
                        forceRefresh: forceRefresh
                    ) {
                        templatesBuilder.append(template)

                        // Find current workout's template by matching templateServerId
                        if workout.templateServerId == program.currentWorkout?.templateServerId {
                            nextTemplateFound = template
                        }
                    }
                }
            }

            // Convert to let for Swift 6 concurrency safety
            let finalTemplates = templatesBuilder
            let finalNextTemplate = nextTemplateFound

            await MainActor.run {
                self.activeProgram = activeProgram
                self.nextWorkout = activeProgram?.currentWorkout
                self.nextTemplate = finalNextTemplate
                self.allTemplates = finalTemplates
                self.error = nil
                self.isLoading = false
            }
        } catch {
            // Try to load from cache - need await since programRepository is @MainActor isolated
            let cached = await programRepository.getCachedPrograms().first { $0.isActive }

            await MainActor.run {
                self.activeProgram = cached
                self.nextWorkout = cached?.currentWorkout
                // Reset template state to stay consistent with program
                self.nextTemplate = nil
                self.allTemplates = []
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    /// Clears the current error message
    func clearError() {
        error = nil
    }
}
