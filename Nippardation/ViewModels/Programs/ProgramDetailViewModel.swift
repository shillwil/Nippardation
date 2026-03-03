//
//  ProgramDetailViewModel.swift
//  Nippardation
//
//  ViewModel for displaying and managing a single program's details
//

import Foundation
import Combine

@MainActor
final class ProgramDetailViewModel: ObservableObject {

    // MARK: - Published State

    @Published var program: Program?
    @Published var templates: [Template] = []
    @Published var isLoading = true
    @Published var error: String?

    // MARK: - Dependencies

    private let programRepository: any ProgramRepositoryProtocol
    private let templateRepository: any TemplateRepositoryProtocol
    private let taskManager = TaskManager()

    // MARK: - State

    private let programServerId: String

    // MARK: - Initialization

    init(
        programServerId: String,
        programRepository: (any ProgramRepositoryProtocol)? = nil,
        templateRepository: (any TemplateRepositoryProtocol)? = nil
    ) {
        self.programServerId = programServerId
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository
    }

    // MARK: - Public Methods

    /// Loads the program and its associated templates
    func loadProgram() {
        // Capture serverId before async context
        let serverId = programServerId

        Task {
            await taskManager.run(id: "loadProgram") { [weak self] in
                guard let self = self else { return }

                await MainActor.run { self.isLoading = true }

                do {
                    let program = try await self.programRepository.fetchProgram(
                        serverId: serverId,
                        forceRefresh: true
                    )

                    // Load templates for each workout
                    var templatesBuilder: [Template] = []
                    for workout in program.workouts {
                        if let template = try? await self.templateRepository.fetchTemplate(
                            serverId: workout.templateServerId,
                            forceRefresh: false
                        ) {
                            templatesBuilder.append(template)
                        }
                    }

                    // Convert to let for Swift 6 concurrency safety
                    let finalTemplates = templatesBuilder

                    await MainActor.run {
                        self.program = program
                        self.templates = finalTemplates
                        self.error = nil
                        self.isLoading = false
                    }
                } catch {
                    // Try loading from cache - need await since programRepository is @MainActor isolated
                    let cached = await self.programRepository.getCachedProgram(serverId: serverId)

                    await MainActor.run {
                        if let cached = cached {
                            self.program = cached
                        }
                        self.error = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        }
    }

    /// Advances to the next workout in the program
    func advanceProgram() {
        guard let program = program else { return }

        Task {
            await taskManager.run(id: "advance") { [weak self] in
                guard let self = self else { return }

                do {
                    let updated = try await self.programRepository.advanceToNextWorkout(
                        serverId: program.serverId
                    )

                    await MainActor.run {
                        self.program = updated
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to advance: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Resets the program progress to the beginning
    func resetProgram() {
        guard let currentProgram = program else { return }

        // Capture program values before async context to create reset version
        let resetProgram = Program(
            id: currentProgram.id,
            serverId: currentProgram.serverId,
            name: currentProgram.name,
            description: currentProgram.description,
            daysPerWeek: currentProgram.daysPerWeek,
            durationWeeks: currentProgram.durationWeeks,
            workouts: currentProgram.workouts,
            isActive: currentProgram.isActive,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: currentProgram.isPublic,
            isAiGenerated: currentProgram.isAiGenerated,
            createdAt: currentProgram.createdAt,
            updatedAt: Date(),
            lastFetchedAt: currentProgram.lastFetchedAt
        )

        Task {
            await taskManager.run(id: "reset") { [weak self] in
                guard let self = self else { return }

                do {
                    let updated = try await self.programRepository.updateProgramProgress(resetProgram)

                    await MainActor.run {
                        self.program = updated
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to reset: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Activates the program
    func activateProgram() {
        guard let program = program else { return }

        Task {
            await taskManager.run(id: "activate") { [weak self] in
                guard let self = self else { return }

                do {
                    let updated = try await self.programRepository.setActiveProgram(serverId: program.serverId)

                    await MainActor.run {
                        self.program = updated
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to activate: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Deactivates the program
    func deactivateProgram() {
        guard program != nil else { return }

        Task {
            await taskManager.run(id: "deactivate") { [weak self] in
                guard let self = self else { return }

                do {
                    try await self.programRepository.deactivateProgram()

                    await MainActor.run {
                        // Update local state
                        if var updated = self.program {
                            updated = Program(
                                id: updated.id,
                                serverId: updated.serverId,
                                name: updated.name,
                                description: updated.description,
                                daysPerWeek: updated.daysPerWeek,
                                durationWeeks: updated.durationWeeks,
                                workouts: updated.workouts,
                                isActive: false,
                                currentDayIndex: updated.currentDayIndex,
                                timesCompleted: updated.timesCompleted,
                                isPublic: updated.isPublic,
                                isAiGenerated: updated.isAiGenerated,
                                createdAt: updated.createdAt,
                                updatedAt: Date(),
                                lastFetchedAt: updated.lastFetchedAt
                            )
                            self.program = updated
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to deactivate: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Returns the template for a given workout
    /// - Parameter workout: The program workout
    /// - Returns: The associated template if found
    func templateFor(workout: ProgramWorkout) -> Template? {
        // First check if template is already attached to workout
        if let template = workout.template {
            return template
        }
        // Otherwise look in our loaded templates
        return templates.first { $0.serverId == workout.templateServerId }
    }

    /// Clears the current error message
    func clearError() {
        error = nil
    }
}
