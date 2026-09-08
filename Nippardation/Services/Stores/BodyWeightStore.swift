//
//  BodyWeightStore.swift
//  Nippardation
//
//  Local body-weight log behind the Progress "BODY LB" tile. Persisted per user in UserDefaults.
//
//  Retention: every entry is kept until the user deletes it. The log is user data and is never
//  trimmed by count or age (a daily entry for ten years is a few thousand small structs, well
//  within UserDefaults).
//

import Foundation
import Combine

struct BodyWeightEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let pounds: Double

    init(id: UUID = UUID(), date: Date = Date(), pounds: Double) {
        self.id = id
        self.date = date
        self.pounds = pounds
    }
}

@MainActor
final class BodyWeightStore: ObservableObject {

    static let shared = BodyWeightStore()

    /// Newest first.
    @Published private(set) var entries: [BodyWeightEntry] = []

    var latest: BodyWeightEntry? { entries.first }
    var previous: BodyWeightEntry? { entries.dropFirst().first }

    /// Latest minus previous, when both exist.
    var delta: Double? {
        guard let latest, let previous else { return nil }
        return latest.pounds - previous.pounds
    }

    private let storage: UserScopedDefaults
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard, userIdProvider: (() -> String?)? = nil) {
        let provider = userIdProvider ?? { AuthManager.shared.user?.uid }
        storage = UserScopedDefaults(namespace: "bodyWeight", defaults: defaults, userIdProvider: provider)
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
        entries = (storage.load([BodyWeightEntry].self) ?? []).sorted { $0.date > $1.date }
    }

    /// Appends an entry. Nothing is evicted: see the retention note at the top of the file.
    func log(pounds: Double, date: Date = Date()) {
        guard pounds.isFinite, pounds > 0 else { return }
        var updated = entries
        updated.insert(BodyWeightEntry(date: date, pounds: pounds), at: 0)
        persist(updated)
    }

    func delete(id: UUID) {
        persist(entries.filter { $0.id != id })
    }

    private func persist(_ updated: [BodyWeightEntry]) {
        entries = updated.sorted { $0.date > $1.date }
        storage.save(entries)
    }
}
