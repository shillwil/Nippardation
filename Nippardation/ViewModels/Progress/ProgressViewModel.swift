//
//  ProgressViewModel.swift
//  Nippardation
//
//  State behind the Progress tab: the active plan, the computed stats and the
//  console-formatted strings the screen prints. Numbers come from
//  `ProgressStatsCalculator`; the view model only loads and formats.
//

import Foundation
import Combine

/// The Me / Crew switch on the Progress eyebrow row.
enum ProgressScope: String, CaseIterable, Hashable {
    case me
    case crew

    var label: String {
        switch self {
        case .me: return "ME"
        case .crew: return "CREW"
        }
    }
}

@MainActor
final class ProgressViewModel: ObservableObject {

    /// Where the active plan comes from. Previews and tests pin a plan; the app reads the repository.
    enum PlanSource {
        case repository
        case fixed(Program?)
    }

    // MARK: - Published State

    @Published var scope: ProgressScope = .me
    @Published private(set) var stats = ProgressStats()
    @Published private(set) var activeProgram: Program?
    @Published private(set) var isLoading = false

    // MARK: - Dependencies

    private let programRepository: any ProgramRepositoryProtocol
    private let workoutsProvider: () -> [TrackedWorkout]
    private let planSource: PlanSource
    private let taskManager = TaskManager()

    // MARK: - Initialization

    init(
        programRepository: (any ProgramRepositoryProtocol)? = nil,
        workoutsProvider: (() -> [TrackedWorkout])? = nil,
        planSource: PlanSource = .repository
    ) {
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
        self.workoutsProvider = workoutsProvider ?? { WorkoutManager.shared.completedWorkouts }
        self.planSource = planSource
    }

    // MARK: - Loading

    /// Recomputes every stat from what is already on device, then reloads the active plan
    /// and recomputes once more so the plan tile catches up.
    func refresh() {
        Task { @MainActor in
            await taskManager.run(id: "refreshProgress") { [weak self] in
                await self?.performRefresh()
            }
        }
    }

    /// Recomputes the stats from the current workouts without touching the repository.
    func recompute() {
        stats = ProgressStatsCalculator.compute(workouts: workoutsProvider(), program: activeProgram)
    }

    private func performRefresh() async {
        isLoading = true
        // Streak, volume, PRs and the chart only need the completed workouts, so print them
        // before the repository answers. Seed the plan from the local cache so the plan tile
        // has something to show too; the awaited result below corrects it.
        if activeProgram == nil, case .repository = planSource {
            activeProgram = programRepository.getCachedPrograms().first { $0.isActive }
        }
        recompute()
        let program = await loadActiveProgram()
        guard !Task.isCancelled else {
            isLoading = false
            return
        }
        activeProgram = program
        recompute()
        isLoading = false
    }

    private func loadActiveProgram() async -> Program? {
        switch planSource {
        case .fixed(let program):
            return program
        case .repository:
            do {
                return try await programRepository.getActiveProgram()
            } catch {
                // Offline or signed out: fall back to whatever is cached.
                return programRepository.getCachedPrograms().first { $0.isActive }
            }
        }
    }

    // MARK: - Streak hero

    /// "03"
    var streakValue: String {
        VoidFormat.pad2(stats.streakWeeks)
    }

    /// "WEEK STREAK · 04 / 05 THIS WEEK" — or "WEEK STREAK · 04 THIS WEEK" without a plan.
    var streakCaption: String {
        let week: String
        if let planned = stats.plannedThisWeek {
            week = "\(VoidFormat.ratio(stats.doneThisWeek, planned)) THIS WEEK"
        } else {
            week = "\(VoidFormat.pad2(stats.doneThisWeek)) THIS WEEK"
        }
        return VoidFormat.readout(["WEEK STREAK", week])
    }

    /// Spoken form of the streak hero.
    var streakAccessibilityLabel: String {
        let streak = "\(stats.streakWeeks) week streak"
        if let planned = stats.plannedThisWeek {
            return "\(streak), \(stats.doneThisWeek) of \(planned) workouts this week"
        }
        return "\(streak), \(stats.doneThisWeek) workouts this week"
    }

    // MARK: - Stat tiles

    /// ("38.4", "K") or ("640", nil)
    var volumeValue: (number: String, unit: String?) {
        VoidFormat.volume(stats.volumeThisWeek)
    }

    /// "VOLUME · ↑ 6%" — the delta is omitted when last week had no volume.
    var volumeLabel: String {
        VoidFormat.readout(["VOLUME", stats.volumeDeltaPercent.map(VoidFormat.deltaPercent)])
    }

    /// "02"
    var prsValue: String {
        VoidFormat.pad2(stats.prsThisWeek)
    }

    /// "12", or "—" without a plan.
    var planValue: String {
        stats.planCompletedWorkouts.map(VoidFormat.pad2) ?? "—"
    }

    /// " / 40" for finite plans, nil for indefinite plans or no plan.
    var planUnit: String? {
        stats.planTotalWorkouts.map { " / \(VoidFormat.pad2($0))" }
    }

    /// Bar fill for finite plans only.
    var planProgress: Double? {
        stats.planProgress
    }

    /// "THE OG · WK 03 / 08", "THE OG · WK 03" (indefinite) or "NO PLAN".
    var planLabel: String {
        guard let program = activeProgram else { return "NO PLAN" }
        guard let week = stats.planCurrentWeek else { return program.name }
        let weekPart: String
        if let total = stats.planTotalWeeks {
            weekPart = "WK \(VoidFormat.ratio(week, total))"
        } else {
            weekPart = "WK \(VoidFormat.pad2(week))"
        }
        return VoidFormat.readout([program.name, weekPart])
    }

    /// "182.4" or "—" before the first log.
    func bodyValue(latest: BodyWeightEntry?) -> String {
        latest.map { VoidFormat.weight($0.pounds) } ?? "—"
    }

    /// "BODY LB · ↓ 0.6", "BODY LB" with a single entry, or "BODY LB · TAP TO LOG" with none.
    func bodyLabel(latest: BodyWeightEntry?, delta: Double?) -> String {
        guard latest != nil else { return VoidFormat.readout(["BODY LB", "TAP TO LOG"]) }
        return VoidFormat.readout(["BODY LB", delta.map(VoidFormat.deltaValue)])
    }

    // MARK: - Chart

    /// "08 WK"
    var chartWeeksLabel: String {
        "\(VoidFormat.pad2(ProgressStatsCalculator.chartWeeks)) WK"
    }

    /// Spoken summary of the weekly bars, oldest first.
    var chartAccessibilityLabel: String {
        let counts = stats.weeklyCounts
        guard let current = counts.last else { return "Workouts per week: no data yet" }
        let past = counts.dropLast().map(String.init).joined(separator: ", ")
        if past.isEmpty {
            return "Workouts this week: \(current)"
        }
        return "Workouts per week over the last \(counts.count) weeks: \(past), and \(current) this week"
    }
}
