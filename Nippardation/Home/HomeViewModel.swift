//
//  HomeViewModel.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//

import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    // Active program data
    @Published var activeProgram: Program?
    @Published var nextWorkout: ProgramWorkout?
    @Published var nextTemplate: Template?
    @Published var previewDayIndex: Int = 0

    // Stats
    @Published var workoutsThisWeek: Int = 0
    @Published var totalVolumeFormatted: String = "0"
    @Published var weeklyConsistency: Int = 0

    @Published var isLoading = false
    @Published var error: String?
    @Published var hasAnyPrograms: Bool?
    @Published var userTemplates: [Template] = []

    private let programRepository: any ProgramRepositoryProtocol
    private let templateRepository: any TemplateRepositoryProtocol
    private let taskManager = TaskManager()

    init(
        programRepository: (any ProgramRepositoryProtocol)? = nil,
        templateRepository: (any TemplateRepositoryProtocol)? = nil
    ) {
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository
    }

    // MARK: - Loading

    func loadDashboard() {
        Task { @MainActor in
            await taskManager.run(id: "loadDashboard") { [weak self] in
                guard let self else { return }
                await MainActor.run { self.isLoading = true }

                do {
                    let program = try await self.programRepository.getActiveProgram()
                    let resolvedIndex = program?.currentDayIndex ?? 0
                    let resolvedWorkout = program.flatMap { self.workoutAt(resolvedIndex, in: $0) }
                    await MainActor.run {
                        self.activeProgram = program
                        self.previewDayIndex = resolvedIndex
                        self.nextWorkout = resolvedWorkout
                        self.nextTemplate = resolvedWorkout?.template
                    }

                    // Load template if not attached to workout
                    if let workout = resolvedWorkout, workout.template == nil {
                        let templates = try await self.templateRepository.fetchTemplates()
                        await MainActor.run {
                            if self.nextWorkout?.id == workout.id {
                                self.nextTemplate = templates.first { $0.serverId == workout.templateServerId }
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.error = error.localizedDescription
                    }
                }

                await MainActor.run { self.isLoading = false }
            }
        }
    }

    // MARK: - Preview Rotation

    nonisolated private func sortedWorkouts(_ program: Program) -> [ProgramWorkout] {
        program.workouts.sorted { $0.dayNumber < $1.dayNumber }
    }

    nonisolated private func workoutAt(_ index: Int, in program: Program) -> ProgramWorkout? {
        let list = sortedWorkouts(program)
        guard !list.isEmpty else { return nil }
        let count = list.count
        let wrapped = ((index % count) + count) % count
        return list[wrapped]
    }

    func rotatePreviewForward() {
        guard let program = activeProgram, program.workouts.count > 1 else { return }
        let count = program.workouts.count
        previewDayIndex = ((previewDayIndex + 1) % count + count) % count
        refreshPreviewedWorkout(program: program)
    }

    func rotatePreviewBackward() {
        guard let program = activeProgram, program.workouts.count > 1 else { return }
        let count = program.workouts.count
        previewDayIndex = ((previewDayIndex - 1) % count + count) % count
        refreshPreviewedWorkout(program: program)
    }

    private func refreshPreviewedWorkout(program: Program) {
        let workout = workoutAt(previewDayIndex, in: program)
        nextWorkout = workout
        nextTemplate = workout?.template

        if let workout, workout.template == nil {
            let currentId = workout.id
            Task { @MainActor in
                guard let templates = try? await self.templateRepository.fetchTemplates() else { return }
                if self.nextWorkout?.id == currentId {
                    self.nextTemplate = templates.first { $0.serverId == workout.templateServerId }
                }
            }
        }
    }

    /// Syncs the server's currentDayIndex forward to match previewDayIndex via repeated advance calls.
    /// No-op when already in sync. On failure, surfaces an error and stops.
    func commitPreviewBeforeStart() async {
        guard let program = activeProgram, !program.workouts.isEmpty else { return }
        let count = program.workouts.count
        var steps = ((previewDayIndex - program.currentDayIndex) % count + count) % count
        guard steps > 0 else { return }
        var latest = program
        while steps > 0 {
            do {
                latest = try await programRepository.advanceToNextWorkout(serverId: latest.serverId)
                steps -= 1
            } catch {
                self.error = "Couldn't update program: \(error.localizedDescription)"
                return
            }
        }
        self.activeProgram = latest
        self.previewDayIndex = latest.currentDayIndex
    }

    /// Advances the program one step (call after a workout finishes from this card).
    func advanceAfterCompletion() async {
        guard let program = activeProgram else { return }
        do {
            let updated = try await programRepository.advanceToNextWorkout(serverId: program.serverId)
            self.activeProgram = updated
            self.previewDayIndex = updated.currentDayIndex
            refreshPreviewedWorkout(program: updated)
        } catch {
            // Non-fatal: next dashboard load will reconcile
        }
    }

    func computeWeeklyStats(from completedWorkouts: [TrackedWorkout]) {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now

        // Workouts this week
        workoutsThisWeek = completedWorkouts.filter { $0.date >= startOfWeek }.count

        // Total volume (last 30 days)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let recentWorkouts = completedWorkouts.filter { $0.date >= thirtyDaysAgo }
        var totalVolume: Double = 0
        for workout in recentWorkouts {
            for exercise in workout.trackedExercises {
                for set in exercise.trackedSets {
                    totalVolume += set.weight * Double(set.reps)
                }
            }
        }
        if totalVolume >= 1000 {
            totalVolumeFormatted = String(format: "%.1fK lbs", totalVolume / 1000)
        } else {
            totalVolumeFormatted = String(format: "%.0f lbs", totalVolume)
        }

        // Weekly consistency (last 4 weeks)
        let fourWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -4, to: now) ?? now
        let lastFourWeeksWorkouts = completedWorkouts.filter { $0.date >= fourWeeksAgo }
        var weeksWithWorkouts = 0
        for weekOffset in 0..<4 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: startOfWeek) ?? now
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? now
            if lastFourWeeksWorkouts.contains(where: { $0.date >= weekStart && $0.date < weekEnd }) {
                weeksWithWorkouts += 1
            }
        }
        weeklyConsistency = weeksWithWorkouts * 25 // out of 100%
    }

    func checkForPrograms() {
        Task { @MainActor in
            do {
                let programs = try await programRepository.fetchPrograms(forceRefresh: false)
                self.hasAnyPrograms = !programs.isEmpty
            } catch {
                let cached = programRepository.getCachedPrograms()
                self.hasAnyPrograms = !cached.isEmpty
            }

            do {
                let templates = try await templateRepository.fetchTemplates(forceRefresh: false)
                self.userTemplates = templates
            } catch {
                self.userTemplates = templateRepository.getCachedTemplates()
            }
        }
    }

    func clearError() {
        error = nil
    }
}
