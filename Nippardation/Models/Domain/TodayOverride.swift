//
//  TodayOverride.swift
//  Nippardation
//
//  What Today runs instead of the scheduled workout. Set from Swap Workout; valid for one calendar day.
//

import Foundation

enum TodayOverride: Codable, Equatable, Hashable {
    /// Run this template today in place of the scheduled one. The scheduled one stays next in the rotation.
    case template(serverId: String)
    /// Skip today. The up-next workout is unchanged and shows tomorrow.
    case rest

    var isRest: Bool {
        if case .rest = self { return true }
        return false
    }

    var templateServerId: String? {
        if case .template(let id) = self { return id }
        return nil
    }
}

/// A day-scoped override record.
struct TodayOverrideRecord: Codable, Equatable {
    /// "yyyy-MM-dd" in the user's calendar.
    let dayKey: String
    let override: TodayOverride

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
