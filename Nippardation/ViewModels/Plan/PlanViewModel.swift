//
//  PlanViewModel.swift
//  Nippardation
//
//  State behind the Plan tab: the active plan, its resolved workouts, the rotation rows
//  and the ··· menu actions (restart, pause, delete with AI workout clean-up).
//

import Foundation
import Combine

@MainActor
final class PlanViewModel: ObservableObject {

    // MARK: - Published State

    /// The active plan, nil when there is none (the view falls through to the Plans hub).
    @Published private(set) var program: Program?
    /// Full workouts for the plan's days, matched by server id.
    @Published private(set) var templates: [Template] = []
    /// One row per workout day: done / up next / later.
    @Published private(set) var rows: [RotationRow] = []
    @Published private(set) var stats = ProgressStats()
    @Published private(set) var isLoading = false
    /// True once the first load finished, so an empty state is not shown before we know.
    @Published private(set) var hasLoaded = false
    /// A menu action (restart / pause / delete) is in flight.
    @Published private(set) var isBusy = false
    @Published var error: String?

    /// Bumps after any action here changed the plan so the view can tell `AppNavigation`.
    @Published private(set) var planMutation = 0

    // MARK: - Menu / delete flow

    @Published var showRestartAlert = false
    @Published var showSimpleDeleteAlert = false
    @Published var showTemplateDeleteSheet = false
    @Published private(set) var programToDeleteDetail: Program?
    @Published private(set) var isFetchingDeleteDetail = false
    @Published private(set) var isDeletingProgram = false

    // MARK: - Dependencies

    private let programRepository: any ProgramRepositoryProtocol
    private let templateRepository: any TemplateRepositoryProtocol
    private let taskManager = TaskManager()
    private var cancellables = Set<AnyCancellable>()

    /// Completed workouts used for the done state and the week readout.
    private var completedWorkouts: [TrackedWorkout]
    /// Preview support: a frozen view model never touches a repository.
    private var isFrozen = false

    // MARK: - Initialization

    /// - Parameters:
    ///   - workoutManager: source of completed workouts (defaults to `WorkoutManager.shared`)
    ///   - completedWorkouts: fixed completed workouts (previews / tests); skips the manager entirely
    init(
        programRepository: (any ProgramRepositoryProtocol)? = nil,
        templateRepository: (any TemplateRepositoryProtocol)? = nil,
        workoutManager: WorkoutManager? = nil,
        completedWorkouts: [TrackedWorkout]? = nil
    ) {
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository

        if let completedWorkouts {
            self.completedWorkouts = completedWorkouts
        } else {
            let manager = workoutManager ?? WorkoutManager.shared
            self.completedWorkouts = manager.completedWorkouts
            manager.$completedWorkouts
                .receive(on: DispatchQueue.main)
                .sink { [weak self] workouts in
                    self?.completedWorkouts = workouts
                    self?.rebuild()
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - Derived

    var hasPlan: Bool { program != nil }

    /// "WK 03 / 08", or "WK 03" for an ongoing plan.
    var weekEyebrow: String? {
        guard let current = stats.planCurrentWeek else { return nil }
        if let total = stats.planTotalWeeks {
            return "WK \(VoidFormat.ratio(current, total))"
        }
        return "WK \(VoidFormat.pad2(current))"
    }

    // MARK: - Loading

    /// Loads the active plan and resolves its workouts. Safe to call repeatedly.
    func load() {
        guard !isFrozen else { return }

        Task {
            await taskManager.runOnMain(id: "load") { [weak self] in
                guard let self else { return }
                if self.program == nil { self.isLoading = true }

                do {
                    let program = try await self.programRepository.getActiveProgram()
                    let templates = await self.resolveTemplates(for: program)
                    if Task.isCancelled { return }
                    self.program = program
                    self.templates = templates
                } catch {
                    if Task.isCancelled { return }
                    // Offline: fall back to whatever is cached; the hub handles the empty case.
                    let cached = self.programRepository.getCachedPrograms().first { $0.isActive }
                    self.program = cached
                    self.templates = cached.map { $0.workouts.compactMap(\.template) } ?? []
                }

                self.rebuild()
                self.isLoading = false
                self.hasLoaded = true
            }
        }
    }

    /// Fetches the full workout for every distinct day (cache first), falling back to the embedded summary.
    private func resolveTemplates(for program: Program?) async -> [Template] {
        guard let program else { return [] }
        var seen = Set<String>()
        var resolved: [Template] = []
        for workout in program.workouts.sorted(by: { $0.dayNumber < $1.dayNumber }) {
            let id = workout.templateServerId
            guard !id.isEmpty, !seen.contains(id) else { continue }
            seen.insert(id)
            if let full = try? await templateRepository.fetchTemplate(serverId: id, forceRefresh: false) {
                resolved.append(full)
            } else if let embedded = workout.template {
                resolved.append(embedded)
            }
        }
        return resolved
    }

    /// Rebuilds rows + stats from the current plan, workouts and completed history.
    private func rebuild() {
        guard let program else {
            rows = []
            stats = ProgressStats()
            return
        }
        rows = PlanRotationBuilder.rows(for: program, templates: templates, completedWorkouts: completedWorkouts)
        stats = ProgressStatsCalculator.compute(workouts: completedWorkouts, program: program)
    }

    /// A workout was edited from a row; keep the rotation in sync without a round trip.
    func handleTemplateSaved(_ template: Template) {
        if let index = templates.firstIndex(where: { $0.serverId == template.serverId }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
        rebuild()
    }

    // MARK: - Menu actions

    /// Restart from day 1: currentDayIndex = 0, timesCompleted = 0. History is untouched.
    func restart() {
        guard let program, !isBusy else { return }
        isBusy = true

        Task {
            await taskManager.runOnMain(id: "restart") { [weak self] in
                guard let self else { return }
                do {
                    let updated = try await self.programRepository.resetProgram(serverId: program.serverId)
                    self.program = self.merged(updated, keeping: program)
                    self.rebuild()
                    self.planMutation &+= 1
                } catch {
                    self.error = "Couldn't restart the plan: \(error.localizedDescription)"
                }
                self.isBusy = false
            }
        }
    }

    /// Pause plan: deactivates it. The view then falls through to the Plans hub.
    func pause() {
        guard program != nil, !isBusy else { return }
        isBusy = true

        Task {
            await taskManager.runOnMain(id: "pause") { [weak self] in
                guard let self else { return }
                do {
                    try await self.programRepository.deactivateProgram()
                    self.program = nil
                    self.templates = []
                    self.rebuild()
                    self.planMutation &+= 1
                } catch {
                    self.error = "Couldn't pause the plan: \(error.localizedDescription)"
                }
                self.isBusy = false
            }
        }
    }

    // MARK: - Delete flow

    /// Fetches the plan detail; AI plans with workouts get the keep/delete sheet, everything else a simple alert.
    func prepareDelete() {
        guard let program, !isFetchingDeleteDetail else { return }
        isFetchingDeleteDetail = true

        Task {
            await taskManager.runOnMain(id: "prepareDelete") { [weak self] in
                guard let self else { return }
                do {
                    // Always fetch detail: the list/active endpoints may omit isAiGenerated or the workouts.
                    let detail = try await self.programRepository.fetchProgram(
                        serverId: program.serverId,
                        forceRefresh: true
                    )
                    let hasTemplates = detail.workouts.contains { $0.template != nil }
                    self.isFetchingDeleteDetail = false
                    if detail.isAiGenerated && hasTemplates {
                        self.programToDeleteDetail = detail
                        self.showTemplateDeleteSheet = true
                    } else {
                        self.showSimpleDeleteAlert = true
                    }
                } catch {
                    self.isFetchingDeleteDetail = false
                    // Fall back to the simple delete when the detail fetch fails.
                    self.showSimpleDeleteAlert = true
                }
            }
        }
    }

    /// Deletes the plan without touching any workout.
    func deleteProgram() {
        guard let program, !isBusy else { return }
        isBusy = true

        Task {
            await taskManager.runOnMain(id: "delete") { [weak self] in
                guard let self else { return }
                do {
                    try await self.programRepository.deleteProgram(serverId: program.serverId)
                    self.finishDelete()
                } catch {
                    self.error = "Couldn't delete the plan: \(error.localizedDescription)"
                }
                self.isBusy = false
            }
        }
    }

    /// Deletes an AI plan and its AI workouts, except the ones the user chose to keep.
    func deleteProgramWithTemplates(keepTemplateIds: [String]) {
        guard let detail = programToDeleteDetail, !isDeletingProgram else { return }
        // Take the ids from the detail we already fetched; don't rely on reading them back from cache later.
        let allTemplateIds = Array(Set(detail.workouts.map(\.templateServerId)))
        isDeletingProgram = true

        Task {
            await taskManager.runOnMain(id: "delete") { [weak self] in
                guard let self else { return }
                do {
                    try await self.programRepository.deleteProgram(
                        serverId: detail.serverId,
                        deleteTemplates: true,
                        keepTemplateIds: keepTemplateIds,
                        programTemplateIds: allTemplateIds
                    )
                    self.isDeletingProgram = false
                    self.finishDelete()
                } catch {
                    self.isDeletingProgram = false
                    self.error = "Couldn't delete the plan: \(error.localizedDescription)"
                }
            }
        }
    }

    func clearDeleteState() {
        programToDeleteDetail = nil
        showTemplateDeleteSheet = false
        showSimpleDeleteAlert = false
    }

    func clearError() {
        error = nil
    }

    // MARK: - Helpers

    private func finishDelete() {
        program = nil
        templates = []
        rebuild()
        clearDeleteState()
        planMutation &+= 1
    }

    /// Some endpoints return the plan without its days; keep the ones we already have in that case.
    private func merged(_ updated: Program, keeping previous: Program) -> Program {
        guard updated.workouts.isEmpty, !previous.workouts.isEmpty else { return updated }
        var merged = updated
        merged.workouts = previous.workouts
        return merged
    }
}

// MARK: - Preview Support

extension PlanViewModel {

    /// A frozen view model with fixed data. `load()` is a no-op.
    static func preview(
        program: Program?,
        templates: [Template] = [],
        completedWorkouts: [TrackedWorkout] = []
    ) -> PlanViewModel {
        let viewModel = PlanViewModel(completedWorkouts: completedWorkouts)
        viewModel.isFrozen = true
        viewModel.program = program
        viewModel.templates = templates
        viewModel.hasLoaded = true
        viewModel.rebuild()
        return viewModel
    }
}
