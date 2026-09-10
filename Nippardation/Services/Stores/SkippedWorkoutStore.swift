//
//  SkippedWorkoutStore.swift
//  Nippardation
//
//  Holds the plan days the user skipped. Scoped to the signed-in user, like the other
//  Void stores. Records are kept for a few weeks — long enough for the rotation and the
//  week readouts that use them — and pruned on every write so this never grows unbounded.
//

import Foundation
import Combine

@MainActor
final class SkippedWorkoutStore: ObservableObject {

    static let shared = SkippedWorkoutStore()

    /// Every retained skip, newest last.
    @Published private(set) var skipped: [SkippedWorkout] = []

    private let storage: UserScopedDefaults
    private var cancellables = Set<AnyCancellable>()

    /// Skips older than this are dropped. The rotation only reads the current week; the
    /// extra headroom keeps a skip legible if the user comes back a couple of weeks later.
    private static let retention: TimeInterval = 8 * 7 * 24 * 60 * 60

    init(defaults: UserDefaults = .standard, userIdProvider: (() -> String?)? = nil) {
        let provider = userIdProvider ?? { AuthManager.shared.user?.uid }
        storage = UserScopedDefaults(namespace: "skippedWorkouts", defaults: defaults, userIdProvider: provider)
        refresh()

        if userIdProvider == nil {
            AuthManager.shared.$user
                .map { $0?.uid }
                .removeDuplicates()
                .dropFirst()
                .sink { [weak self] _ in Task { @MainActor [weak self] in self?.refresh() } }
                .store(in: &cancellables)
        }
    }

    /// Re-reads the records for the current user, dropping anything past the retention window.
    func refresh(now: Date = Date()) {
        let stored = storage.load([SkippedWorkout].self) ?? []
        let kept = Self.pruned(stored, now: now)
        skipped = kept
        if kept.count != stored.count {
            persist(kept)
        }
    }

    /// Records a skip. Replaces an existing skip for the same plan day rather than stacking them.
    func record(_ skip: SkippedWorkout, now: Date = Date()) {
        var next = skipped.filter { !($0.programServerId == skip.programServerId && $0.workoutId == skip.workoutId) }
        next.append(skip)
        next = Self.pruned(next, now: now)
        skipped = next
        persist(next)
    }

    /// Undoes a skip — used when the plan advance it was recorded for fails.
    func remove(id: UUID) {
        let next = skipped.filter { $0.id != id }
        guard next.count != skipped.count else { return }
        skipped = next
        persist(next)
    }

    /// Drops every skip belonging to a plan. Called when that plan is restarted or deleted,
    /// so a fresh cycle doesn't inherit the last one's skipped days.
    func clear(programServerId: String) {
        let next = skipped.filter { $0.programServerId != programServerId }
        guard next.count != skipped.count else { return }
        skipped = next
        persist(next)
    }

    func clear() {
        skipped = []
        storage.clear()
    }

    // MARK: - Helpers

    private func persist(_ records: [SkippedWorkout]) {
        if records.isEmpty {
            storage.clear()
        } else {
            storage.save(records)
        }
    }

    private static func pruned(_ records: [SkippedWorkout], now: Date) -> [SkippedWorkout] {
        records
            .filter { now.timeIntervalSince($0.date) <= retention }
            .sorted { $0.date < $1.date }
    }
}
