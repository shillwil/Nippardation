//
//  VoidCalendar.swift
//  Nippardation
//
//  The app's week runs Monday → Sunday (MON … SUN in the console labels).
//

import Foundation

enum VoidCalendar {
    /// The user's calendar with weeks starting on Monday.
    static var current: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    /// Start of the week containing `date`.
    static func startOfWeek(_ date: Date, calendar: Calendar = VoidCalendar.current) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    /// Half-open interval [start, end) of the week `offset` weeks before the one containing `date`.
    static func weekInterval(offset: Int, from date: Date, calendar: Calendar = VoidCalendar.current) -> DateInterval {
        let start = startOfWeek(date, calendar: calendar)
        let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: start) ?? start
        let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? weekStart
        return DateInterval(start: weekStart, end: weekEnd)
    }
}

extension DateInterval {
    /// Half-open containment: start ≤ date < end.
    func containsHalfOpen(_ date: Date) -> Bool {
        date >= start && date < end
    }
}
