//
//  ReceivedPlan.swift
//  Nippardation
//
//  A plan (or single workout) someone sent the user, kept locally under Plan → Sent to you.
//  The share itself lives on the backend and is re-fetched by token when opened.
//

import Foundation

struct ReceivedPlan: Identifiable, Codable, Equatable, Hashable {
    let token: String
    /// "program" or "template" (ShareType raw value).
    let type: String
    let name: String
    let sharedByName: String
    /// Training days in the rotation (1 for a single workout).
    let dayCount: Int
    let estimatedMinutes: Int?
    let durationWeeks: Int?
    let receivedAt: Date
    var isRead: Bool

    var id: String { token }

    var shareType: ShareType { ShareType(rawValue: type) ?? .template }
    var isProgram: Bool { shareType == .program }

    /// "4 days · ~60 min · today"
    func caption(now: Date = Date()) -> String {
        var parts: [String] = []
        parts.append(isProgram ? "\(dayCount) \(dayCount == 1 ? "day" : "days")" : "\(dayCount) workout")
        if let estimatedMinutes, estimatedMinutes > 0 {
            parts.append("~\(estimatedMinutes) min")
        }
        parts.append(VoidFormat.relativeDay(receivedAt, now: now))
        return parts.joined(separator: " · ")
    }

    /// Readout for the received sheet: "4 DAYS · ~60 MIN · 8 WEEKS"
    var readout: String {
        var parts: [String?] = []
        if isProgram {
            parts.append(VoidFormat.days(dayCount))
        } else {
            parts.append("1 WORKOUT")
        }
        if let estimatedMinutes, estimatedMinutes > 0 { parts.append(VoidFormat.minutes(estimatedMinutes)) }
        if let durationWeeks, durationWeeks > 0 { parts.append(VoidFormat.weeks(durationWeeks)) }
        return VoidFormat.readout(parts)
    }
}

// MARK: - From a fetched share

extension ReceivedPlan {
    init(item: SharedItem, receivedAt: Date = Date(), isRead: Bool = false) {
        let sharer = item.sharedBy.displayName?.trimmingCharacters(in: .whitespaces)
        let sharedByName = (sharer?.isEmpty == false ? sharer : nil) ?? item.sharedBy.handle

        switch item.type {
        case .program:
            let program = item.program
            let workouts = program?.workouts ?? []
            let minutes = workouts.compactMap { $0.template?.estimatedDurationMinutes }.filter { $0 > 0 }
            let average = minutes.isEmpty ? nil : minutes.reduce(0, +) / minutes.count
            self.init(
                token: item.token,
                type: ShareType.program.rawValue,
                name: program?.name ?? "Plan",
                sharedByName: sharedByName,
                dayCount: workouts.isEmpty ? (program?.daysPerWeek ?? 0) : workouts.count,
                estimatedMinutes: average,
                durationWeeks: program?.durationWeeks,
                receivedAt: receivedAt,
                isRead: isRead
            )
        case .template:
            let template = item.template
            let minutes = template?.estimatedDurationMinutes ?? 0
            self.init(
                token: item.token,
                type: ShareType.template.rawValue,
                name: template?.name ?? "Workout",
                sharedByName: sharedByName,
                dayCount: 1,
                estimatedMinutes: minutes > 0 ? minutes : nil,
                durationWeeks: nil,
                receivedAt: receivedAt,
                isRead: isRead
            )
        }
    }
}
