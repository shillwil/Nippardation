//
//  TodayViewModel.swift
//  Nippardation
//
//  State behind the Today tab: the active plan, what runs today (the scheduled workout,
//  a Swap Workout override, or a rest day), the streak chip, and the auto-advance that
//  moves the plan forward exactly once when the scheduled workout completes.
//

import Foundation

@MainActor
final class TodayViewModel: ObservableObject {

    /// What Today shows. A workout in progress is layered on top of this by the view.
    enum Mode: Equatable {
        case loading
        case empty
        case scheduled
        case swapped
        case rest
    }

    /// Everything the view needs to hand a workout to `WorkoutManager`.
    struct StartPlan {
        let template: Template
        let fallbackName: String
        /// True for the plan's scheduled workout; completing it advances the plan.
        let isScheduled: Bool
    }

    // MARK: - Published state

    @Published private(set) var activeProgram: Program?
    @Published private(set) var scheduledWorkout: ProgramWorkout?
    @Published private(set) var scheduledIndex: Int = 0
    @Published private(set) var scheduledTemplate: Template?
    @Published private(set) var override: TodayOverride?
    @Published private(set) var overrideTemplate: Template?
    /// Resolved templates for every workout in the plan, keyed by template server id.
    @Published private(set) var planTemplates: [String: Template] = [:]
    @Published private(set) var streakWeeks: Int = 0
    @Published private(set) var hasLoaded = false
    /// Bumps each time the plan auto-advances; the view answers with a haptic and `planDidChange()`.
    @Published private(set) var planAdvanceCount = 0
    @Published var error: String?

    // MARK: - Dependencies

    private let programRepository: any ProgramRepositoryProtocol
    private let templateRepository: any TemplateRepositoryProtocol
    private let overrideStore: TodayOverrideStore
    private let workoutManager: WorkoutManager
    /// The scheduled workout Today started and has not yet advanced for. Survives relaunch.
    private let pendingAdvance: UserScopedDefaults
    private let taskManager = TaskManager()
    private var isFrozenForPreview = false

    private static let pendingAdvanceLifetime: TimeInterval = 24 * 60 * 60
    private static let missingExercisesMessage = "Couldn't load the exercises for this workout. Check your connection, or edit the workout from the Plan tab."

    init(
        programRepository: (any ProgramRepositoryProtocol)? = nil,
        templateRepository: (any TemplateRepositoryProtocol)? = nil,
        overrideStore: TodayOverrideStore? = nil,
        workoutManager: WorkoutManager = .shared
    ) {
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository
        self.overrideStore = overrideStore ?? .shared
        self.workoutManager = workoutManager
        self.pendingAdvance = UserScopedDefaults(
            namespace: "todayPendingAdvance",
            userIdProvider: { AuthManager.shared.user?.uid }
        )
        self.override = self.overrideStore.override
    }

    // MARK: - Derived state

    var mode: Mode {
        guard hasLoaded || activeProgram != nil else { return .loading }
        guard let program = activeProgram, !program.workouts.isEmpty else { return .empty }
        switch override {
        case .some(.rest):
            return .rest
        case .some(.template(let serverId)):
            return serverId == scheduledWorkout?.templateServerId ? .scheduled : .swapped
        case .none:
            return .scheduled
        }
    }

    /// The scheduled workout's display word: template name, else day label, else DAY 02.
    var scheduledName: String {
        Self.word(workout: scheduledWorkout, template: scheduledTemplate, index: scheduledIndex)
    }

    /// The swapped-in workout's display word.
    var swappedName: String {
        guard case .some(.template(let serverId)) = override else { return scheduledName }
        let workout = planWorkout(templateServerId: serverId)
        return Self.word(
            workout: workout,
            template: overrideTemplate ?? planTemplates[serverId],
            index: workout?.dayNumber ?? 0
        )
    }

    /// The template Start runs and Preview Exercises shows (nil while unresolved).
    var upNextTemplate: Template? {
        switch mode {
        case .swapped: return overrideTemplate
        case .scheduled, .rest: return scheduledTemplate
        case .loading, .empty: return nil
        }
    }

    /// "DAY 02 / 05 · THE OG"
    var planReadout: String? {
        guard let program = activeProgram, !program.workouts.isEmpty else { return nil }
        return VoidFormat.readout([
            "DAY \(VoidFormat.ratio(scheduledIndex + 1, program.workouts.count))",
            program.name
        ])
    }

    // MARK: - Loading

    /// Reloads the active plan. Seeds from cache synchronously so the layout never sits empty.
    func load() {
        guard !isFrozenForPreview else { return }
        if activeProgram == nil,
           let cached = programRepository.getCachedPrograms().first(where: { $0.isActive }) {
            applyProgram(cached)
        }
        Task { [weak self] in
            guard let self else { return }
            await self.taskManager.run(id: "load") { [weak self] in
                guard let self else { return }
                await self.performLoad()
            }
        }
    }

    private func performLoad() async {
        do {
            let program = try await programRepository.getActiveProgram()
            if Task.isCancelled { return }
            applyProgram(program)
            await resolvePlanTemplates()
            error = nil
        } catch is CancellationError {
            return
        } catch {
            if let cached = programRepository.getCachedPrograms().first(where: { $0.isActive }) {
                applyProgram(cached)
                await resolvePlanTemplates()
            }
            self.error = error.localizedDescription
        }
        hasLoaded = true
        refreshStreak()
        await advanceIfPendingWorkoutCompleted()
    }

    /// Sets the plan and the scheduled workout from what is already in memory (no fetching).
    private func applyProgram(_ program: Program?) {
        activeProgram = program
        if let program, let scheduled = Self.scheduledSlot(in: program) {
            scheduledWorkout = scheduled.workout
            scheduledIndex = scheduled.index
            scheduledTemplate = planTemplates[scheduled.workout.templateServerId]
                ?? scheduled.workout.template
                ?? templateRepository.getCachedTemplate(serverId: scheduled.workout.templateServerId)
        } else {
            scheduledWorkout = nil
            scheduledIndex = 0
            scheduledTemplate = nil
        }
        if program == nil {
            planTemplates = [:]
        }
        overrideDidChange(overrideStore.override)
    }

    /// Resolves a template with exercises for every workout in the plan.
    private func resolvePlanTemplates() async {
        guard let program = activeProgram else { return }
        var resolved = planTemplates
        let ids = Array(Set(program.workouts.map(\.templateServerId))).filter { !$0.isEmpty }.sorted()
        for id in ids {
            let embedded = program.workouts.first { $0.templateServerId == id }?.template
            if let template = await resolveTemplate(serverId: id, embedded: embedded) {
                resolved[id] = template
            }
            if Task.isCancelled { return }
        }
        planTemplates = resolved
        if let scheduled = scheduledWorkout, let template = resolved[scheduled.templateServerId] {
            scheduledTemplate = template
        }
        overrideDidChange(overrideStore.override)
    }

    /// Uses the embedded template when it already carries exercises; otherwise fetches, then falls back to cache.
    private func resolveTemplate(serverId: String, embedded: Template?) async -> Template? {
        if let embedded, !embedded.exercises.isEmpty { return embedded }
        guard !serverId.isEmpty else { return embedded }
        if let fetched = try? await templateRepository.fetchTemplate(serverId: serverId, forceRefresh: false) {
            return fetched
        }
        return templateRepository.getCachedTemplate(serverId: serverId) ?? embedded
    }

    // MARK: - Override

    /// Called when the override store changes (Swap Workout, Rest day, a new calendar day).
    func overrideDidChange(_ value: TodayOverride?) {
        override = value
        guard case .some(.template(let serverId)) = value else {
            overrideTemplate = nil
            return
        }
        let known = planTemplates[serverId] ?? templateRepository.getCachedTemplate(serverId: serverId)
        overrideTemplate = known
        if let known, !known.exercises.isEmpty { return }

        Task { [weak self] in
            guard let self else { return }
            let resolved = await self.resolveTemplate(serverId: serverId, embedded: known)
            guard case .some(.template(let current)) = self.override, current == serverId else { return }
            if let resolved {
                self.overrideTemplate = resolved
            }
        }
    }

    // MARK: - Streak

    func refreshStreak() {
        streakWeeks = ProgressStatsCalculator.compute(
            workouts: workoutManager.completedWorkouts,
            program: activeProgram
        ).streakWeeks
    }

    // MARK: - Start

    /// Resolves what Start should run. Starting on a rest day clears the rest override first.
    func prepareStart() async -> StartPlan? {
        switch mode {
        case .loading, .empty:
            return nil
        case .rest:
            overrideStore.clear()
            overrideDidChange(nil)
            return await scheduledStart()
        case .scheduled:
            return await scheduledStart()
        case .swapped:
            guard case .some(.template(let serverId)) = override else { return nil }
            var template = overrideTemplate
            if template == nil || template?.exercises.isEmpty == true {
                template = await resolveTemplate(serverId: serverId, embedded: template)
            }
            guard let template, !template.exercises.isEmpty else {
                error = Self.missingExercisesMessage
                return nil
            }
            overrideTemplate = template
            return StartPlan(template: template, fallbackName: swappedName, isScheduled: false)
        }
    }

    private func scheduledStart() async -> StartPlan? {
        guard let workout = scheduledWorkout else { return nil }
        var template = scheduledTemplate
        if template == nil || template?.exercises.isEmpty == true {
            template = await resolveTemplate(serverId: workout.templateServerId, embedded: template ?? workout.template)
        }
        guard let template, !template.exercises.isEmpty else {
            error = Self.missingExercisesMessage
            return nil
        }
        scheduledTemplate = template
        return StartPlan(template: template, fallbackName: scheduledName, isScheduled: true)
    }

    /// Records the started workout so its completion can advance the plan (scheduled starts only).
    func didStart(_ tracked: TrackedWorkout, plan: StartPlan) {
        if plan.isScheduled, let program = activeProgram {
            pendingAdvance.save(PendingAdvanceRecord(
                programServerId: program.serverId,
                workoutId: tracked.id,
                startedAt: Date()
            ))
        } else {
            pendingAdvance.clear()
        }
    }

    /// The template for Preview Exercises, resolving it if it has not been yet.
    func templateForPreview() async -> Template? {
        if let template = upNextTemplate, !template.exercises.isEmpty { return template }
        switch mode {
        case .swapped:
            guard case .some(.template(let serverId)) = override else { return nil }
            let template = await resolveTemplate(serverId: serverId, embedded: overrideTemplate)
            if let template { overrideTemplate = template }
            return template
        case .scheduled, .rest:
            guard let workout = scheduledWorkout else { return nil }
            let template = await resolveTemplate(serverId: workout.templateServerId, embedded: scheduledTemplate ?? workout.template)
            if let template { scheduledTemplate = template }
            return template
        case .loading, .empty:
            return nil
        }
    }

    // MARK: - Completion → auto-advance

    /// Call on "WorkoutDataUpdated". Advances the plan once if the scheduled workout started from Today completed.
    func workoutDataDidUpdate() async {
        workoutManager.loadCompletedWorkouts()
        refreshStreak()
        await advanceIfPendingWorkoutCompleted()
    }

    /// Consumes the pending record before awaiting so a completion advances exactly once,
    /// even though "WorkoutDataUpdated" is posted more than once per finished workout.
    private func advanceIfPendingWorkoutCompleted() async {
        guard let record = pendingAdvance.load(PendingAdvanceRecord.self) else { return }

        // Still running (for example resumed after a relaunch): wait for the completion.
        if let active = workoutManager.activeWorkout, active.id == record.workoutId { return }

        let completed = workoutManager.completedWorkouts.contains { $0.id == record.workoutId && $0.isCompleted }
        guard completed else {
            if Date().timeIntervalSince(record.startedAt) > Self.pendingAdvanceLifetime {
                pendingAdvance.clear()
            }
            return
        }

        pendingAdvance.clear()

        guard let program = activeProgram ?? programRepository.getCachedProgram(serverId: record.programServerId),
              program.serverId == record.programServerId else { return }

        do {
            let updated = try await programRepository.advanceToNextWorkout(serverId: program.serverId)
            overrideStore.clear()
            applyProgram(updated)
            await resolvePlanTemplates()
            refreshStreak()
            planAdvanceCount += 1
        } catch {
            self.error = "Couldn't advance your plan: \(error.localizedDescription)"
        }
    }

    // MARK: - Errors

    func clearError() {
        error = nil
    }

    // MARK: - Helpers

    private func planWorkout(templateServerId: String) -> ProgramWorkout? {
        activeProgram?.workouts
            .sorted { $0.dayNumber < $1.dayNumber }
            .first { $0.templateServerId == templateServerId }
    }

    /// The plan's scheduled workout with its 0-based rotation index (wraps a stale day index).
    nonisolated static func scheduledSlot(in program: Program) -> (workout: ProgramWorkout, index: Int)? {
        let ordered = program.workouts.sorted { $0.dayNumber < $1.dayNumber }
        guard !ordered.isEmpty else { return nil }
        let count = ordered.count
        let index = ((program.currentDayIndex % count) + count) % count
        return (ordered[index], index)
    }

    /// The display word for a plan day: template name, else day label, else DAY 02.
    nonisolated static func word(workout: ProgramWorkout?, template: Template?, index: Int) -> String {
        let name = template?.name.trimmingCharacters(in: .whitespaces) ?? ""
        if !name.isEmpty { return name }
        if let label = workout?.dayLabel?.trimmingCharacters(in: .whitespaces), !label.isEmpty { return label }
        return "DAY \(VoidFormat.pad2(index + 1))"
    }

    /// "06 EXERCISES · ~55 MIN" (nil when nothing is known about the workout yet).
    nonisolated static func caption(for template: Template?) -> String? {
        guard let template else { return nil }
        let count = template.exerciseCount
        guard count > 0 else { return nil }
        let minutes = template.exercises.isEmpty ? nil : VoidFormat.minutes(roundedMinutes(template.estimatedDurationMinutes))
        return VoidFormat.readout([VoidFormat.exercises(count), minutes])
    }

    /// Rounds an estimate to the nearest five minutes, never below five.
    nonisolated static func roundedMinutes(_ minutes: Int) -> Int {
        max(5, ((minutes + 2) / 5) * 5)
    }
}

// MARK: - Pending advance record

private struct PendingAdvanceRecord: Codable, Equatable {
    let programServerId: String
    let workoutId: UUID
    let startedAt: Date
}

// MARK: - Preview support

#if DEBUG
extension TodayViewModel {
    /// A frozen view model for previews: never loads, state seeded from sample data.
    static func preview(program: Program?, store: TodayOverrideStore, streakWeeks: Int = 3) -> TodayViewModel {
        let viewModel = TodayViewModel(
            programRepository: MockProgramRepository(),
            templateRepository: MockTemplateRepository(),
            overrideStore: store
        )
        viewModel.isFrozenForPreview = true
        viewModel.applyProgram(program)
        viewModel.hasLoaded = true
        viewModel.streakWeeks = streakWeeks
        return viewModel
    }
}
#endif
