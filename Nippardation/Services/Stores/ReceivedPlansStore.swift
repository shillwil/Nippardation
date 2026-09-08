//
//  ReceivedPlansStore.swift
//  Nippardation
//
//  Local list of plans sent to the user (Plan → Sent to you). Persisted per user in UserDefaults.
//

import Foundation
import Combine

@MainActor
final class ReceivedPlansStore: ObservableObject {

    static let shared = ReceivedPlansStore()

    @Published private(set) var plans: [ReceivedPlan] = []

    var unreadCount: Int { plans.filter { !$0.isRead }.count }
    var hasUnread: Bool { unreadCount > 0 }

    private let storage: UserScopedDefaults
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard, userIdProvider: (() -> String?)? = nil) {
        let provider = userIdProvider ?? { AuthManager.shared.user?.uid }
        storage = UserScopedDefaults(namespace: "receivedPlans", defaults: defaults, userIdProvider: provider)
        reload()

        if userIdProvider == nil {
            AuthManager.shared.$user
                .map { $0?.uid }
                .removeDuplicates()
                .dropFirst()
                .sink { [weak self] _ in Task { @MainActor [weak self] in self?.reload() } }
                .store(in: &cancellables)
        }
    }

    func reload() {
        plans = (storage.load([ReceivedPlan].self) ?? []).sorted { $0.receivedAt > $1.receivedAt }
    }

    func plan(token: String) -> ReceivedPlan? {
        plans.first { $0.token == token }
    }

    func contains(token: String) -> Bool {
        plan(token: token) != nil
    }

    /// Adds or refreshes a received plan. Preserves `receivedAt` and read state when it already exists.
    func save(_ plan: ReceivedPlan) {
        var updated = plans
        if let index = updated.firstIndex(where: { $0.token == plan.token }) {
            var merged = plan
            merged.isRead = updated[index].isRead || plan.isRead
            updated[index] = ReceivedPlan(
                token: merged.token,
                type: merged.type,
                name: merged.name,
                sharedByName: merged.sharedByName,
                dayCount: merged.dayCount,
                estimatedMinutes: merged.estimatedMinutes,
                durationWeeks: merged.durationWeeks,
                receivedAt: updated[index].receivedAt,
                isRead: merged.isRead
            )
        } else {
            updated.insert(plan, at: 0)
        }
        persist(updated)
    }

    func markRead(token: String) {
        guard let index = plans.firstIndex(where: { $0.token == token }), !plans[index].isRead else { return }
        var updated = plans
        updated[index].isRead = true
        persist(updated)
    }

    func remove(token: String) {
        persist(plans.filter { $0.token != token })
    }

    func removeAll() {
        persist([])
    }

    private func persist(_ updated: [ReceivedPlan]) {
        plans = updated.sorted { $0.receivedAt > $1.receivedAt }
        storage.save(plans)
    }
}
