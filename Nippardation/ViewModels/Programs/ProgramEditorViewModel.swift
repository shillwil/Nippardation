//
//  ProgramEditorViewModel.swift
//  Nippardation
//
//  ViewModel for creating and editing workout programs
//

import Foundation
import Combine

@MainActor
final class ProgramEditorViewModel: ObservableObject {

    // MARK: - Published State

    @Published var name: String = ""
    @Published var description: String = ""
    @Published var daysPerWeek: Int = 3
    @Published var durationWeeks: Int? = nil
    @Published var workouts: [EditableWorkout] = []
    @Published var isIndefinite: Bool = true
    @Published var selectedDays: Set<Int> = []

    @Published var isSaving = false
    @Published var isLoadingTemplates = false
    @Published var error: String?
    @Published var savedProgram: Program?
    @Published var availableTemplates: [Template] = []

    // MARK: - Types

    /// Represents a workout day being edited
    struct EditableWorkout: Identifiable {
        let id = UUID()
        var dayNumber: Int
        var dayLabel: String
        var templateServerId: String?
        var templateName: String?
    }

    // MARK: - Dependencies

    private let programRepository: any ProgramRepositoryProtocol
    private let templateRepository: any TemplateRepositoryProtocol
    private let taskManager = TaskManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - State

    private var existingProgram: Program?
    var isEditing: Bool { existingProgram != nil }

    // MARK: - Computed Properties

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        daysPerWeek > 0 &&
        daysPerWeek <= 7 &&
        workouts.allSatisfy { $0.templateServerId != nil }
    }

    /// Validates Step 1 of the wizard (name + days selected)
    var isStep1Valid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedDays.isEmpty
    }

    // MARK: - Initialization

    init(
        existingProgram: Program? = nil,
        programRepository: (any ProgramRepositoryProtocol)? = nil,
        templateRepository: (any TemplateRepositoryProtocol)? = nil
    ) {
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository

        if let program = existingProgram {
            self.existingProgram = program
            self.name = program.name
            self.description = program.description ?? ""
            self.daysPerWeek = program.daysPerWeek
            self.durationWeeks = program.durationWeeks
            self.isIndefinite = program.isIndefinite
            self.workouts = program.workouts.map { workout in
                EditableWorkout(
                    dayNumber: workout.dayNumber,
                    dayLabel: workout.dayLabel ?? "",
                    templateServerId: workout.templateServerId,
                    templateName: workout.template?.name ?? workout.displayName
                )
            }
        } else {
            // Initialize with empty workouts based on days per week
            updateWorkoutCount()
        }

        // Watch for daysPerWeek changes
        $daysPerWeek
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateWorkoutCount()
            }
            .store(in: &cancellables)

        // Sync selectedDays count with daysPerWeek
        $selectedDays
            .dropFirst()
            .sink { [weak self] days in
                guard let self = self else { return }
                if days.count != self.daysPerWeek {
                    self.daysPerWeek = days.count
                }
            }
            .store(in: &cancellables)

        // Watch for isIndefinite changes
        $isIndefinite
            .dropFirst()
            .sink { [weak self] indefinite in
                if indefinite {
                    self?.durationWeeks = nil
                } else if self?.durationWeeks == nil {
                    self?.durationWeeks = 8 // Default duration
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Loads available templates for workout selection
    func loadTemplates() {
        Task {
            await taskManager.run(id: "loadTemplates") { [weak self] in
                guard let self = self else { return }

                await MainActor.run { self.isLoadingTemplates = true }

                do {
                    let templates = try await self.templateRepository.fetchTemplates(forceRefresh: false)

                    await MainActor.run {
                        self.availableTemplates = templates
                        self.isLoadingTemplates = false
                    }
                } catch {
                    // Need await since templateRepository is @MainActor isolated
                    let cachedTemplates = await self.templateRepository.getCachedTemplates()
                    await MainActor.run {
                        // Fall back to cached templates
                        self.availableTemplates = cachedTemplates
                        self.isLoadingTemplates = false
                    }
                }
            }
        }
    }

    /// Updates the workout count to match daysPerWeek
    func updateWorkoutCount() {
        let currentCount = workouts.count

        if daysPerWeek > currentCount {
            // Add workouts
            for i in currentCount..<daysPerWeek {
                workouts.append(EditableWorkout(
                    dayNumber: i,
                    dayLabel: "Day \(i + 1)",
                    templateServerId: nil,
                    templateName: nil
                ))
            }
        } else if daysPerWeek < currentCount {
            // Remove workouts
            workouts = Array(workouts.prefix(daysPerWeek))
        }

        // Renumber
        for i in 0..<workouts.count {
            workouts[i].dayNumber = i
        }
    }

    /// Sets the template for a workout at the given index
    /// - Parameters:
    ///   - template: The template to assign
    ///   - workoutIndex: The index of the workout to update
    func setTemplate(_ template: Template, for workoutIndex: Int) {
        guard workoutIndex >= 0 && workoutIndex < workouts.count else { return }
        workouts[workoutIndex].templateServerId = template.serverId
        workouts[workoutIndex].templateName = template.name
    }

    /// Updates the label for a workout at the given index
    /// - Parameters:
    ///   - label: The new label
    ///   - workoutIndex: The index of the workout to update
    func setLabel(_ label: String, for workoutIndex: Int) {
        guard workoutIndex >= 0 && workoutIndex < workouts.count else { return }
        workouts[workoutIndex].dayLabel = label
    }

    /// Saves the program (creates new or updates existing)
    func save() {
        guard isValid else { return }

        // Capture @MainActor properties before entering async context
        let capturedName = name
        let capturedDescription = description
        let capturedDaysPerWeek = daysPerWeek
        let capturedIsIndefinite = isIndefinite
        let capturedDurationWeeks = durationWeeks
        let capturedWorkouts = workouts
        let capturedAvailableTemplates = availableTemplates
        let capturedExisting = existingProgram

        Task {
            await taskManager.run(id: "save") { [weak self] in
                guard let self = self else { return }

                await MainActor.run { self.isSaving = true }

                do {
                    let programWorkouts = capturedWorkouts.compactMap { workout -> ProgramWorkout? in
                        guard let templateServerId = workout.templateServerId else { return nil }
                        let template = capturedAvailableTemplates.first { $0.serverId == templateServerId }
                        return ProgramWorkout(
                            id: UUID(),
                            serverId: "",
                            dayNumber: workout.dayNumber,
                            dayLabel: workout.dayLabel.isEmpty ? nil : workout.dayLabel,
                            templateServerId: templateServerId,
                            template: template
                        )
                    }

                    let program: Program

                    if let existing = capturedExisting {
                        // Update existing
                        let updatedProgram = Program(
                            id: existing.id,
                            serverId: existing.serverId,
                            name: capturedName,
                            description: capturedDescription.isEmpty ? nil : capturedDescription,
                            daysPerWeek: capturedDaysPerWeek,
                            durationWeeks: capturedIsIndefinite ? nil : capturedDurationWeeks,
                            workouts: programWorkouts,
                            isActive: existing.isActive,
                            currentDayIndex: existing.currentDayIndex,
                            timesCompleted: existing.timesCompleted,
                            isPublic: existing.isPublic,
                            isAiGenerated: existing.isAiGenerated,
                            createdAt: existing.createdAt,
                            updatedAt: Date(),
                            lastFetchedAt: existing.lastFetchedAt
                        )
                        program = try await self.programRepository.updateProgram(updatedProgram)
                    } else {
                        // Create new
                        let newProgram = Program(
                            id: UUID(),
                            serverId: "",
                            name: capturedName,
                            description: capturedDescription.isEmpty ? nil : capturedDescription,
                            daysPerWeek: capturedDaysPerWeek,
                            durationWeeks: capturedIsIndefinite ? nil : capturedDurationWeeks,
                            workouts: programWorkouts,
                            isActive: false,
                            currentDayIndex: 0,
                            timesCompleted: 0,
                            isPublic: false,
                            isAiGenerated: false,
                            createdAt: Date(),
                            updatedAt: Date(),
                            lastFetchedAt: nil
                        )
                        program = try await self.programRepository.createProgram(newProgram)
                    }

                    await MainActor.run {
                        self.savedProgram = program
                        self.isSaving = false
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to save: \(error.localizedDescription)"
                        self.isSaving = false
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
