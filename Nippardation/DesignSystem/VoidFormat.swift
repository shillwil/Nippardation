//
//  VoidFormat.swift
//  Nippardation
//
//  Console-style formatting for Void labels and readouts:
//  zero-padded counts (DAY 02 / 05), volume in K (38.4K), dates (TUE · 09.08).
//

import Foundation

enum VoidFormat {

    /// The separator used between readout parts.
    static let dot = " · "

    /// Zero-pads to two digits: 2 → "02", 12 → "12", 120 → "120".
    static func pad2(_ value: Int) -> String {
        value < 0 ? "-" + pad2(-value) : String(format: "%02d", value)
    }

    /// "02 / 05"
    static func ratio(_ done: Int, _ total: Int) -> String {
        "\(pad2(done)) / \(pad2(total))"
    }

    /// Joins non-empty parts with " · ".
    static func readout(_ parts: [String?]) -> String {
        parts.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: dot)
    }

    /// Volume with one decimal in K when ≥ 1000: 38 400 → ("38.4", "K"); 640 → ("640", nil).
    static func volume(_ pounds: Double) -> (number: String, unit: String?) {
        let v = max(0, pounds)
        if v >= 1000 {
            return (String(format: "%.1f", v / 1000), "K")
        }
        return (String(format: "%.0f", v), nil)
    }

    /// Body weight with one decimal: 182.4
    static func weight(_ pounds: Double) -> String {
        String(format: "%.1f", pounds)
    }

    /// Signed percent delta for readouts: 6 → "↑ 6%", -3 → "↓ 3%", 0 → "→ 0%".
    static func deltaPercent(_ percent: Int) -> String {
        if percent > 0 { return "↑ \(percent)%" }
        if percent < 0 { return "↓ \(-percent)%" }
        return "→ 0%"
    }

    /// Signed absolute delta with one decimal: -0.6 → "↓ 0.6"
    static func deltaValue(_ value: Double) -> String {
        if value > 0 { return String(format: "↑ %.1f", value) }
        if value < 0 { return String(format: "↓ %.1f", -value) }
        return "→ 0.0"
    }

    /// "TUE · 09.08"
    static func dateEyebrow(_ date: Date, calendar: Calendar = .current) -> String {
        "\(weekday(date, calendar: calendar))\(dot)\(monthDay(date, calendar: calendar))"
    }

    /// "09.08"
    static func monthDay(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.month, .day], from: date)
        return "\(pad2(c.month ?? 0)).\(pad2(c.day ?? 0))"
    }

    /// "TUE" — always English three-letter, uppercase, to match the console vocabulary.
    static func weekday(_ date: Date, calendar: Calendar = .current) -> String {
        let index = calendar.component(.weekday, from: date) // 1 = Sunday
        return weekdayLabels[(index - 1 + 7) % 7]
    }

    /// Sunday-first labels matching Calendar's weekday numbering.
    static let weekdayLabels = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    /// Monday-first labels for a seven-day strip.
    static let weekStripLabels = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

    /// "~55 MIN"
    static func minutes(_ minutes: Int) -> String {
        "~\(minutes) MIN"
    }

    /// "06 EXERCISES"
    static func exercises(_ count: Int) -> String {
        "\(pad2(count)) \(count == 1 ? "EXERCISE" : "EXERCISES")"
    }

    /// "4 DAYS"
    static func days(_ count: Int) -> String {
        "\(count) \(count == 1 ? "DAY" : "DAYS")"
    }

    /// "8 WEEKS"
    static func weeks(_ count: Int) -> String {
        "\(count) \(count == 1 ? "WEEK" : "WEEKS")"
    }

    /// Relative day for received-plan captions: "today", "yesterday", "Aug 30".
    static func relativeDay(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return "today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return "yesterday"
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = calendar.component(.year, from: date) == calendar.component(.year, from: now) ? "MMM d" : "MMM d, yyyy"
        return f.string(from: date)
    }

    /// Up to two initials for an avatar square: "The OG" → "TO", "Marcus" → "M".
    static func initials(_ name: String) -> String {
        let words = name.split(whereSeparator: { $0 == " " || $0 == "-" || $0 == "/" }).filter { !$0.isEmpty }
        let letters = words.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }
        if letters.isEmpty { return "?" }
        return letters.joined()
    }
}
