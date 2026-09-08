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
    @Published var selectedDays: Set<Int> = [] {
        didSet {
            handleSelectedDaysChange(from: oldValue)
        }
    }
    @Published var restDays: Set<Int> = []

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
    private var previousSelectedDays: Set<Int> = []
    var isEditing: Bool { existingProgram != nil }

    // MARK: - Computed Properties

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        daysPerWeek > 0 &&
        daysPerWeek <= 7 &&
        workouts.enumerated().allSatisfy { index, workout in
            restDays.contains(index) || workout.templateServerId != nil
        }
    }

    /// Validates Step 1 of the wizard (name + days selected)
    var isStep1Valid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedDays.isEmpty
    }

    /// Validates Step 2 of the wizard (all non-rest days have templates, at least one training day)
    var isStep2Valid: Bool {
        var hasTrainingDay = false
        for (index, workout) in workouts.enumerated() {
            if restDays.contains(index) { continue }
            if workout.templateServerId == nil { return false }
            hasTrainingDay = true
        }
        return hasTrainingDay
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
            // Array position is load-bearing (save() renumbers by index), so never trust the payload order.
            self.workouts = program.workouts.sorted { $0.dayNumber < $1.dayNumber }.map { workout in
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
            .sink { [weak self] newDaysPerWeek in
                // @Published emits during willSet; use the published value instead of reading self.daysPerWeek.
                self?.updateWorkoutCount(targetCount: newDaysPerWeek)
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

    /// Rebuilds workouts when selectedDays changes, preserving day-of-week template associations
    private func rebuildWorkouts(for newDays: Set<Int>) {
        let oldSorted = previousSelectedDays.sorted()
        let newSorted = newDays.sorted()

        // Map old day-of-week → (workout, isRest) from current state
        var dayWorkoutMap: [Int: EditableWorkout] = [:]
        var dayIsRest: [Int: Bool] = [:]
        for (index, dayOfWeek) in oldSorted.enumerated() where index < workouts.count {
            dayWorkoutMap[dayOfWeek] = workouts[index]
            dayIsRest[dayOfWeek] = restDays.contains(index)
        }

        // Rebuild for new selection, preserving day-of-week associations
        var newWorkouts: [EditableWorkout] = []
        var newRestDays: Set<Int> = []
        for (newIndex, dayOfWeek) in newSorted.enumerated() {
            if var existing = dayWorkoutMap[dayOfWeek] {
                let oldDayNumber = existing.dayNumber
                existing.dayNumber = newIndex
                existing.dayLabel = renumberedEditableDayLabel(
                    existing.dayLabel,
                    from: oldDayNumber,
                    to: newIndex
                )
                newWorkouts.append(existing)
                if dayIsRest[dayOfWeek] == true {
                    newRestDays.insert(newIndex)
                }
            } else {
                newWorkouts.append(EditableWorkout(
                    dayNumber: newIndex,
                    dayLabel: "Day \(newIndex + 1)",
                    templateServerId: nil,
                    templateName: nil
                ))
            }
        }

        workouts = newWorkouts
        restDays = newRestDays
        previousSelectedDays = newDays
    }

    /// Keeps workout rows synchronized with selected calendar days in the wizard.
    private func handleSelectedDaysChange(from oldDays: Set<Int>) {
        guard selectedDays != oldDays else { return }
        rebuildWorkouts(for: selectedDays)
        if selectedDays.count != daysPerWeek {
            daysPerWeek = selectedDays.count
        }
    }

    /// Updates the workout count to match the target day count.
    func updateWorkoutCount(targetCount: Int? = nil) {
        let targetCount = targetCount ?? daysPerWeek
        let currentCount = workouts.count
        guard targetCount != currentCount else { return }

        if targetCount > currentCount {
            // Add workouts
            for i in currentCount..<targetCount {
                workouts.append(EditableWorkout(
                    dayNumber: i,
                    dayLabel: "Day \(i + 1)",
                    templateServerId: nil,
                    templateName: nil
                ))
            }
        } else if targetCount < currentCount {
            // Remove workouts
            workouts = Array(workouts.prefix(targetCount))
            // Remove stale rest day indices that are now out of range
            restDays = restDays.filter { $0 < targetCount }
        }

        // Renumber
        for i in 0..<workouts.count {
            let oldDayNumber = workouts[i].dayNumber
            workouts[i].dayNumber = i
            workouts[i].dayLabel = renumberedEditableDayLabel(
                workouts[i].dayLabel,
                from: oldDayNumber,
                to: i
            )
        }
    }

    /// Toggles a workout day as a rest day
    func toggleRestDay(at index: Int) {
        guard index >= 0 && index < workouts.count else { return }
        if restDays.contains(index) {
            restDays.remove(index)
        } else {
            restDays.insert(index)
            // Clear template assignment when marking as rest
            workouts[index].templateServerId = nil
            workouts[index].templateName = nil
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

        // Ensure newly created templates are available for other day assignments and program save
        if !availableTemplates.contains(where: { $0.serverId == template.serverId }) {
            availableTemplates.append(template)
        }
    }

    /// Updates the label for a workout at the given index
    /// - Parameters:
    ///   - label: The new label
    ///   - workoutIndex: The index of the workout to update
    func setLabel(_ label: String, for workoutIndex: Int) {
        guard workoutIndex >= 0 && workoutIndex < workouts.count else { return }
        workouts[workoutIndex].dayLabel = label
    }

    // MARK: - Day List Editing (Edit plan)

    /// The rotation is capped at one workout day per weekday, matching the wizard.
    static let maxWorkouts = 7

    var canAddWorkout: Bool { workouts.count < Self.maxWorkouts }

    /// Appends a new, unassigned day at the end of the rotation.
    func addWorkout() {
        guard canAddWorkout else { return }
        let index = workouts.count
        workouts.append(EditableWorkout(
            dayNumber: index,
            dayLabel: defaultDayLabel(for: index),
            templateServerId: nil,
            templateName: nil
        ))
        syncDaysPerWeek()
    }

    /// Removes the day at `index`, keeping rest-day flags, day numbers and "Day N" labels consistent.
    func removeWorkout(at index: Int) {
        guard workouts.indices.contains(index) else { return }
        removeWorkouts(at: IndexSet(integer: index))
    }

    /// Removes the days at `offsets` (List `.onDelete`).
    func removeWorkouts(at offsets: IndexSet) {
        let valid = offsets.filteredIndexSet { workouts.indices.contains($0) }
        guard !valid.isEmpty else { return }
        var flagged = flaggedWorkouts()
        flagged.remove(atOffsets: valid)
        applyFlaggedWorkouts(flagged)
        syncDaysPerWeek()
    }

    /// Moves days (List `.onMove`), carrying rest-day flags with the rows and renumbering.
    func moveWorkouts(from source: IndexSet, to destination: Int) {
        var flagged = flaggedWorkouts()
        flagged.move(fromOffsets: source, toOffset: destination)
        applyFlaggedWorkouts(flagged)
    }

    /// Workouts paired with their rest-day flag so both survive a reorder or removal together.
    private func flaggedWorkouts() -> [(workout: EditableWorkout, isRest: Bool)] {
        workouts.enumerated().map { (workout: $0.element, isRest: restDays.contains($0.offset)) }
    }

    private func applyFlaggedWorkouts(_ flagged: [(workout: EditableWorkout, isRest: Bool)]) {
        var renumbered: [EditableWorkout] = []
        var newRestDays = Set<Int>()
        for (index, entry) in flagged.enumerated() {
            var workout = entry.workout
            let oldDayNumber = workout.dayNumber
            workout.dayNumber = index
            workout.dayLabel = renumberedEditableDayLabel(workout.dayLabel, from: oldDayNumber, to: index)
            renumbered.append(workout)
            if entry.isRest {
                newRestDays.insert(index)
            }
        }
        workouts = renumbered
        restDays = newRestDays
    }

    /// Keeps `daysPerWeek` equal to the number of days in the rotation (the wizard's invariant).
    /// The `$daysPerWeek` observer sees an equal count and leaves the rows alone.
    private func syncDaysPerWeek() {
        let count = workouts.count
        guard count >= 1, count <= Self.maxWorkouts, daysPerWeek != count else { return }
        daysPerWeek = count
    }

    /// Saves the program (creates new or updates existing)
    func save() {
        guard isValid && isStep2Valid else { return }

        // Capture @MainActor properties before entering async context
        let capturedName = name
        let capturedDescription = description
        let trainingDaysPerWeek = workouts.enumerated().filter { !restDays.contains($0.offset) }.count
        let capturedDaysPerWeek = trainingDaysPerWeek
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
                    }.enumerated().map { index, workout in
                        // Renumber after filtering rest days to avoid gaps
                        ProgramWorkout(
                            id: workout.id,
                            serverId: workout.serverId,
                            dayNumber: index,
                            dayLabel: self.renumberedProgramWorkoutLabel(
                                workout.dayLabel,
                                from: workout.dayNumber,
                                to: index
                            ),
                            templateServerId: workout.templateServerId,
                            template: workout.template
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
                            // Server-owned: updateProgram sends no progress fields, so a local clamp would be
                            // discarded anyway. Every reader wraps the index into the rotation length.
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

    // MARK: - Label Helpers

    nonisolated private func defaultDayLabel(for dayNumber: Int) -> String {
        "Day \(dayNumber + 1)"
    }

    /// Keep auto-generated "Day N" labels aligned with day-number changes while preserving custom labels.
    nonisolated private func renumberedEditableDayLabel(_ label: String, from oldDayNumber: Int, to newDayNumber: Int) -> String {
        label == defaultDayLabel(for: oldDayNumber) ? defaultDayLabel(for: newDayNumber) : label
    }

    nonisolated private func renumberedProgramWorkoutLabel(_ label: String?, from oldDayNumber: Int, to newDayNumber: Int) -> String? {
        guard let label else { return nil }
        return label == defaultDayLabel(for: oldDayNumber) ? defaultDayLabel(for: newDayNumber) : label
    }
}
