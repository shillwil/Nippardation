//
//  TodayOverrideStore.swift
//  Nippardation
//
//  Holds today's Swap Workout / Rest day override. Scoped to a calendar day and to the signed-in user.
//  The store owns the day scoping: it re-checks the record on every read path that matters
//  (launch, sign-in change, the calendar day rolling over, the app returning to the foreground),
//  so readers can trust `override` to belong to the current date.
//

import Foundation
import Combine
import UIKit

@MainActor
final class TodayOverrideStore: ObservableObject {

    static let shared = TodayOverrideStore()

    /// The override for the current calendar day, if any.
    @Published private(set) var override: TodayOverride?

    private let storage: UserScopedDefaults
    private let calendar: Calendar
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current, userIdProvider: (() -> String?)? = nil) {
        let provider = userIdProvider ?? { AuthManager.shared.user?.uid }
        self.calendar = calendar
        storage = UserScopedDefaults(namespace: "todayOverride", defaults: defaults, userIdProvider: provider)
        refresh()

        if userIdProvider == nil {
            AuthManager.shared.$user
                .map { $0?.uid }
                .removeDuplicates()
                .dropFirst()
                .sink { [weak self] _ in Task { @MainActor [weak self] in self?.refresh() } }
                .store(in: &cancellables)

            // Valid for one calendar day: drop yesterday's override when the day rolls over while the
            // app is up, and when it comes back to the foreground (a tab's onAppear does not re-fire).
            NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
                .merge(with: NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
                .sink { [weak self] _ in Task { @MainActor [weak self] in self?.refresh() } }
                .store(in: &cancellables)
        }
    }

    /// Re-reads the record and drops it if it belongs to another day.
    func refresh(now: Date = Date()) {
        let today = TodayOverrideRecord.dayKey(for: now, calendar: calendar)
        if let record = storage.load(TodayOverrideRecord.self), record.dayKey == today {
            override = record.override
        } else {
            if storage.load(TodayOverrideRecord.self) != nil {
                storage.clear()
            }
            override = nil
        }
    }

    func set(_ override: TodayOverride, on date: Date = Date()) {
        let record = TodayOverrideRecord(dayKey: TodayOverrideRecord.dayKey(for: date, calendar: calendar), override: override)
        storage.save(record)
        self.override = override
    }

    func clear() {
        storage.clear()
        override = nil
    }
}
