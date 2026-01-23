//
//  TemplateEditorViewModel.swift
//  Nippardation
//
//  ViewModel for creating and editing workout templates
//

import Foundation
import Combine

@MainActor
final class TemplateEditorViewModel: ObservableObject {

    // MARK: - Published State

    @Published var name: String = ""
    @Published var description: String = ""
    @Published var exercises: [EditableExercise] = []

    @Published var isSaving = false
    @Published var error: String?
    @Published var savedTemplate: Template?

    // MARK: - Types

    /// Represents an exercise being edited in the template
    struct EditableExercise: Identifiable {
        let id = UUID()
        var orderIndex: Int
        var exerciseServerId: String
        var exerciseLibraryItem: ExerciseLibraryItem?
        var warmupSets: Int
        var workingSets: Int
        var targetReps: String
        var restSeconds: Int
        var notes: String

        var displayName: String {
            exerciseLibraryItem?.name ?? "Unknown Exercise"
        }
    }

    // MARK: - Dependencies

    private let templateRepository: any TemplateRepositoryProtocol
    private let taskManager = TaskManager()

    // MARK: - State

    private var existingTemplate: Template?
    var isEditing: Bool { existingTemplate != nil }

    // MARK: - Computed Properties

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !exercises.isEmpty
    }

    var totalWorkingSets: Int {
        exercises.reduce(0) { $0 + $1.workingSets }
    }

    var totalWarmupSets: Int {
        exercises.reduce(0) { $0 + $1.warmupSets }
    }

    // MARK: - Initialization

    init(
        existingTemplate: Template? = nil,
        templateRepository: (any TemplateRepositoryProtocol)? = nil
    ) {
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository

        if let template = existingTemplate {
            self.existingTemplate = template
            self.name = template.name
            self.description = template.description ?? ""
            self.exercises = template.exercises.map { exercise in
                EditableExercise(
                    orderIndex: exercise.orderIndex,
                    exerciseServerId: exercise.exerciseServerId,
                    exerciseLibraryItem: exercise.exerciseLibraryItem,
                    warmupSets: exercise.warmupSets ?? 0,
                    workingSets: exercise.workingSets,
                    targetReps: exercise.targetReps ?? "8-12",
                    restSeconds: exercise.restSeconds ?? 90,
                    notes: exercise.notes ?? ""
                )
            }
        }
    }

    // MARK: - Public Methods

    /// Adds an exercise to the template
    /// - Parameter exercise: The exercise library item to add
    func addExercise(_ exercise: ExerciseLibraryItem) {
        let newExercise = EditableExercise(
            orderIndex: exercises.count,
            exerciseServerId: exercise.serverId,
            exerciseLibraryItem: exercise,
            warmupSets: 0,
            workingSets: 3,
            targetReps: "8-12",
            restSeconds: 90,
            notes: ""
        )
        exercises.append(newExercise)
        reorderExercises()
    }

    /// Adds multiple exercises to the template
    /// - Parameter exerciseItems: The exercise library items to add
    func addExercises(_ exerciseItems: [ExerciseLibraryItem]) {
        for exercise in exerciseItems {
            addExercise(exercise)
        }
    }

    /// Removes an exercise at the given index
    /// - Parameter index: The index to remove
    func removeExercise(at index: Int) {
        guard index < exercises.count else { return }
        exercises.remove(at: index)
        reorderExercises()
    }

    /// Removes exercises at the given offsets (for SwiftUI list editing)
    /// - Parameter offsets: The index set of exercises to remove
    func removeExercises(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
        reorderExercises()
    }

    /// Moves exercises within the list
    /// - Parameters:
    ///   - source: Source indices
    ///   - destination: Destination index
    func moveExercises(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        reorderExercises()
    }

    /// Updates an exercise at the given index
    /// - Parameters:
    ///   - index: The index to update
    ///   - warmupSets: New warmup sets count
    ///   - workingSets: New working sets count
    ///   - targetReps: New target reps string
    ///   - restSeconds: New rest period
    ///   - notes: New notes
    func updateExercise(
        at index: Int,
        warmupSets: Int? = nil,
        workingSets: Int? = nil,
        targetReps: String? = nil,
        restSeconds: Int? = nil,
        notes: String? = nil
    ) {
        guard index < exercises.count else { return }
        if let warmupSets = warmupSets {
            exercises[index].warmupSets = warmupSets
        }
        if let workingSets = workingSets {
            exercises[index].workingSets = workingSets
        }
        if let targetReps = targetReps {
            exercises[index].targetReps = targetReps
        }
        if let restSeconds = restSeconds {
            exercises[index].restSeconds = restSeconds
        }
        if let notes = notes {
            exercises[index].notes = notes
        }
    }

    /// Saves the template (creates new or updates existing)
    func save() {
        guard isValid else { return }

        // Capture @MainActor properties before entering async context
        let capturedName = name
        let capturedDescription = description
        let capturedExercises = exercises
        let capturedExisting = existingTemplate

        Task {
            await taskManager.run(id: "save") { [weak self] in
                guard let self = self else { return }

                await MainActor.run { self.isSaving = true }

                do {
                    let templateExercises = capturedExercises.map { exercise in
                        TemplateExercise(
                            id: UUID(),
                            serverId: "",
                            exerciseServerId: exercise.exerciseServerId,
                            exerciseLibraryItem: exercise.exerciseLibraryItem,
                            orderIndex: exercise.orderIndex,
                            warmupSets: exercise.warmupSets > 0 ? exercise.warmupSets : nil,
                            workingSets: exercise.workingSets,
                            targetReps: exercise.targetReps.isEmpty ? nil : exercise.targetReps,
                            restSeconds: exercise.restSeconds > 0 ? exercise.restSeconds : nil,
                            notes: exercise.notes.isEmpty ? nil : exercise.notes
                        )
                    }

                    let template: Template

                    if let existing = capturedExisting {
                        // Update existing
                        let updatedTemplate = Template(
                            id: existing.id,
                            serverId: existing.serverId,
                            name: capturedName,
                            description: capturedDescription.isEmpty ? nil : capturedDescription,
                            exercises: templateExercises,
                            isPublic: existing.isPublic,
                            isAiGenerated: existing.isAiGenerated,
                            createdAt: existing.createdAt,
                            updatedAt: Date(),
                            lastFetchedAt: existing.lastFetchedAt
                        )
                        template = try await self.templateRepository.updateTemplate(updatedTemplate)
                    } else {
                        // Create new
                        let newTemplate = Template(
                            id: UUID(),
                            serverId: "",
                            name: capturedName,
                            description: capturedDescription.isEmpty ? nil : capturedDescription,
                            exercises: templateExercises,
                            isPublic: false,
                            isAiGenerated: false,
                            createdAt: Date(),
                            updatedAt: Date(),
                            lastFetchedAt: nil
                        )
                        template = try await self.templateRepository.createTemplate(newTemplate)
                    }

                    await MainActor.run {
                        self.savedTemplate = template
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

    // MARK: - Private Helpers

    private func reorderExercises() {
        for i in 0..<exercises.count {
            exercises[i].orderIndex = i
        }
    }
}
