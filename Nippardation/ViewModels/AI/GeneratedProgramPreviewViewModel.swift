//
//  GeneratedProgramPreviewViewModel.swift
//  Nippardation
//
//  ViewModel for previewing and editing an AI-generated program before saving
//

import Foundation

@MainActor
final class GeneratedProgramPreviewViewModel: ObservableObject {

    // MARK: - Editable State

    @Published var programName: String
    @Published var programDescription: String
    @Published var workouts: [EditableWorkout]

    // MARK: - UI State

    @Published var isSaving = false
    @Published var error: String?
    @Published var savedSuccessfully = false

    // MARK: - Types

    struct EditableWorkout: Identifiable {
        let id = UUID()
        let serverId: String
        var dayLabel: String
        var exercises: [EditableExercise]
    }

    struct EditableExercise: Identifiable {
        let id = UUID()
        let serverId: String
        var name: String
        var workingSets: Int
        var targetReps: String
        var restSeconds: Int
        var warmupSets: Int
    }

    // MARK: - Source Data

    let originalProgram: Program
    let metadata: GenerationMetadataDTO?

    // MARK: - Dependencies

    private let programRepository: any ProgramRepositoryProtocol

    // MARK: - Initialization

    init(
        program: Program,
        metadata: GenerationMetadataDTO?,
        programRepository: (any ProgramRepositoryProtocol)? = nil
    ) {
        self.originalProgram = program
        self.metadata = metadata
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository

        self.programName = program.name
        self.programDescription = program.description ?? ""
        self.workouts = program.workouts.sorted(by: { $0.dayNumber < $1.dayNumber }).map { workout in
            EditableWorkout(
                serverId: workout.serverId,
                dayLabel: workout.dayLabel ?? workout.displayName,
                exercises: (workout.template?.exercises ?? []).sorted(by: { $0.orderIndex < $1.orderIndex }).map { exercise in
                    EditableExercise(
                        serverId: exercise.serverId,
                        name: exercise.displayName,
                        workingSets: exercise.workingSets,
                        targetReps: exercise.targetReps ?? "8-12",
                        restSeconds: exercise.restSeconds ?? 90,
                        warmupSets: exercise.warmupSets ?? 0
                    )
                }
            )
        }
    }

    // MARK: - Computed

    var totalExercises: Int {
        workouts.reduce(0) { $0 + $1.exercises.count }
    }

    var generationTimeFormatted: String? {
        guard let timeMs = metadata?.timeMs else { return nil }
        let seconds = Double(timeMs) / 1000.0
        return String(format: "%.1fs", seconds)
    }

    // MARK: - Edit Actions

    func removeExercise(workoutIndex: Int, exerciseIndex: Int) {
        guard workoutIndex < workouts.count,
              exerciseIndex < workouts[workoutIndex].exercises.count else { return }
        workouts[workoutIndex].exercises.remove(at: exerciseIndex)
    }

    func moveExercise(workoutIndex: Int, from source: IndexSet, to destination: Int) {
        guard workoutIndex < workouts.count else { return }
        workouts[workoutIndex].exercises.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Save

    func save() {
        isSaving = true
        error = nil

        Task { [weak self] in
            guard let self else { return }

            do {
                // Build updated program with edits applied
                let updatedProgram = Program(
                    id: self.originalProgram.id,
                    serverId: self.originalProgram.serverId,
                    name: self.programName,
                    description: self.programDescription.isEmpty ? nil : self.programDescription,
                    daysPerWeek: self.originalProgram.daysPerWeek,
                    durationWeeks: self.originalProgram.durationWeeks,
                    workouts: self.originalProgram.workouts,
                    isActive: false,
                    currentDayIndex: 0,
                    timesCompleted: 0,
                    isPublic: false,
                    isAiGenerated: true,
                    createdAt: self.originalProgram.createdAt,
                    updatedAt: Date(),
                    lastFetchedAt: self.originalProgram.lastFetchedAt
                )

                // Update program metadata on server if name/description changed
                if updatedProgram.name != self.originalProgram.name ||
                   updatedProgram.description != self.originalProgram.description {
                    _ = try await self.programRepository.updateProgram(updatedProgram)
                }

                // Cache the program locally
                try await self.programRepository.cacheProgram(updatedProgram)

                await MainActor.run {
                    self.isSaving = false
                    self.savedSuccessfully = true
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.error = "Failed to save program: \(error.localizedDescription)"
                }
            }
        }
    }

    func clearError() {
        error = nil
    }
}
