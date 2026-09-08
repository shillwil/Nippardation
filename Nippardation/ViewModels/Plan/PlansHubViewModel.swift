//
//  PlansHubViewModel.swift
//  Nippardation
//
//  State for the Plans hub: the user's plans (active first) with their captions,
//  and the plans people sent them. Program loading, activation, duplication and the
//  delete flows are delegated to `ProgramListViewModel`; its changes are forwarded.
//

import Foundation
import Combine

@MainActor
final class PlansHubViewModel: ObservableObject {

    /// One row under YOUR PLANS.
    struct PlanRow: Identifiable {
        let program: Program
        let isActive: Bool
        /// Previously run but not active: dimmed like the spec's archived rows.
        let isPaused: Bool
        let caption: String
        var id: UUID { program.id }
        var initials: String { VoidFormat.initials(program.name) }
    }

    // MARK: - Dependencies

    let programs: ProgramListViewModel
    let received: ReceivedPlansStore
    private var cancellables = Set<AnyCancellable>()

    /// Bumps after a plan was activated, duplicated or deleted (the view forwards it to `AppNavigation`).
    @Published private(set) var mutationCount = 0

    init(programs: ProgramListViewModel? = nil, received: ReceivedPlansStore? = nil) {
        self.programs = programs ?? ProgramListViewModel()
        self.received = received ?? ReceivedPlansStore.shared

        self.programs.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        self.received.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        self.programs.onMutation = { [weak self] in
            self?.mutationCount &+= 1
        }
    }

    // MARK: - Sent to you

    var receivedPlans: [ReceivedPlan] { received.plans }
    var unreadCount: Int { received.unreadCount }

    /// "1 NEW" while something is unread.
    var receivedTrailing: String? {
        unreadCount > 0 ? "\(unreadCount) NEW" : nil
    }

    func removeReceived(_ plan: ReceivedPlan) {
        received.remove(token: plan.token)
    }

    // MARK: - Your plans

    var isLoading: Bool { programs.isLoading }
    var error: String? { programs.error }

    /// Active plan first, then most recently updated.
    var planRows: [PlanRow] {
        programs.programs
            .sorted { a, b in
                if a.isActive != b.isActive { return a.isActive }
                return a.updatedAt > b.updatedAt
            }
            .map { program in
                let paused = !program.isActive && (program.timesCompleted > 0 || program.currentDayIndex > 0)
                return PlanRow(
                    program: program,
                    isActive: program.isActive,
                    isPaused: paused,
                    caption: Self.caption(for: program)
                )
            }
    }

    var hasPlans: Bool { !programs.programs.isEmpty }

    func load(refresh: Bool = true) {
        programs.loadPrograms(refresh: refresh)
    }

    func activate(_ program: Program) {
        programs.activateProgram(program)
    }

    func duplicate(_ program: Program) {
        programs.duplicateProgram(program)
    }

    func prepareDelete(_ program: Program) {
        programs.prepareDeleteProgram(program)
    }

    // MARK: - Captions

    /// "Active · 5 days · week 3 of 8" · "5 days · 8 weeks" · "Paused · 5 days · 8 weeks"
    static func caption(for program: Program) -> String {
        let days = program.daysPerWeek > 0 ? program.daysPerWeek : program.workouts.count
        let dayText = "\(days) \(days == 1 ? "day" : "days")"
        var parts: [String] = []

        if program.isActive {
            parts.append("Active")
            parts.append(dayText)
            let week = currentWeek(of: program)
            if let total = program.durationWeeks, total > 0 {
                parts.append("week \(min(week, total)) of \(total)")
            } else {
                parts.append("week \(week)")
            }
        } else {
            if program.timesCompleted > 0 || program.currentDayIndex > 0 {
                parts.append("Paused")
            }
            parts.append(dayText)
            if let total = program.durationWeeks, total > 0 {
                parts.append("\(total) \(total == 1 ? "week" : "weeks")")
            }
        }
        return parts.joined(separator: " · ")
    }

    /// 1-based week the plan is in, from completed rotations and the current day index.
    static func currentWeek(of program: Program) -> Int {
        let rotation = program.workouts.isEmpty ? max(program.daysPerWeek, 1) : program.workouts.count
        let perWeek = max(program.daysPerWeek, 1)
        let completedDays = program.timesCompleted * rotation + program.currentDayIndex
        return completedDays / perWeek + 1
    }
}
