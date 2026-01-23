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

                await MainActor.run { self.isLoading = true }

                do {
                    // Load active program
                    let activeProgram = try await self.programRepository.getActiveProgram()

                    var templatesBuilder: [Template] = []
                    var nextTemplateFound: Template?

                    if let program = activeProgram {
                        // Load templates for the program
                        for workout in program.workouts {
                            if let template = try? await self.templateRepository.fetchTemplate(
                                serverId: workout.templateServerId,
                                forceRefresh: false
                            ) {
                                templatesBuilder.append(template)

                                // Find current workout's template
                                if workout.dayNumber == program.currentDayIndex {
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
                    let cached = await self.programRepository.getCachedPrograms().first { $0.isActive }

                    await MainActor.run {
                        self.activeProgram = cached
                        self.nextWorkout = cached?.currentWorkout
                        self.error = error.localizedDescription
                        self.isLoading = false
                    }
                }
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
        // Check attached template first
        if let template = workout.template {
            return template
        }
        // Otherwise look in loaded templates
        return allTemplates.first { $0.serverId == workout.templateServerId }
    }

    /// Refreshes the dashboard data
    func refresh() {
        loadDashboard()
    }

    /// Clears the current error message
    func clearError() {
        error = nil
    }
}
