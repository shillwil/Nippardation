//
//  PlanRotationBuilder.swift
//  Nippardation
//
//  Turns the active plan into the rows the Plan tab draws: one per workout day with
//  a tile state (done / next / later) and a weekday label. Pure, unit-testable.
//

import Foundation

struct RotationRow: Identifiable, Equatable {
    let id: UUID
    /// Position in the rotation (0-based).
    let index: Int
    let workout: ProgramWorkout
    let template: Template?
    let state: WorkoutTileState
    /// "MON", "TUE" …
    let weekday: String
    /// The date this row is projected onto (actual completion date for done rows).
    let date: Date

    var isUpNext: Bool { state == .next }
    var isDone: Bool { state == .done }

    /// The display word: template name, else day label, else "DAY 02".
    var word: String {
        let name = template?.name.trimmingCharacters(in: .whitespaces) ?? ""
        if !name.isEmpty { return name }
        if let label = workout.dayLabel?.trimmingCharacters(in: .whitespaces), !label.isEmpty { return label }
        return "DAY \(VoidFormat.pad2(index + 1))"
    }

    var glyph: VoidIcon {
        VoidIcon.workoutGlyph(for: template?.name ?? workout.dayLabel)
    }

    /// "MON · DONE" · "▮ TUE · UP NEXT" · "WED"
    var eyebrow: String {
        switch state {
        case .done: return "\(weekday)\(VoidFormat.dot)DONE"
        case .next: return VoidGlyphs.upNext("\(weekday)\(VoidFormat.dot)UP NEXT")
        case .later: return weekday
        }
    }

    static func == (lhs: RotationRow, rhs: RotationRow) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state && lhs.weekday == rhs.weekday && lhs.index == rhs.index
    }
}

enum PlanRotationBuilder {

    /// Builds rows for `program`.
    /// - Parameters:
    ///   - program: the active plan (rows follow `dayNumber` order)
    ///   - templates: resolved templates (matched by serverId; falls back to the embedded template)
    ///   - completedWorkouts: completed workouts; only this week's matter for `done`
    ///   - todayOverride: today's Swap Workout / Rest day override. A Rest day skips today, so the
    ///     up-next row (and the rows projected from it) read as tomorrow.
    ///   - now: today
    static func rows(
        for program: Program,
        templates: [Template] = [],
        completedWorkouts: [TrackedWorkout] = [],
        todayOverride: TodayOverride? = nil,
        now: Date = Date(),
        calendar: Calendar = VoidCalendar.current
    ) -> [RotationRow] {
        let ordered = program.workouts.sorted { $0.dayNumber < $1.dayNumber }
        guard !ordered.isEmpty else { return [] }

        let count = ordered.count
        let currentIndex = ((program.currentDayIndex % count) + count) % count
        let week = VoidCalendar.weekInterval(offset: 0, from: now, calendar: calendar)
        // This week's completions, oldest first. Each one is consumed by at most one row, so a plan
        // that repeats a template (Upper / Lower / Upper / Lower) marks only the rows actually done
        // and earlier rotation rows take the earlier completion dates.
        var pool = completedWorkouts
            .filter { $0.isCompleted && week.containsHalfOpen($0.date) }
            .sorted { $0.date < $1.date }
        let today = calendar.startOfDay(for: now)
        // Rest day: today is skipped, the up-next workout is unchanged and shows tomorrow.
        let anchor: Date
        if todayOverride?.isRest == true {
            anchor = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        } else {
            anchor = today
        }

        return ordered.enumerated().map { index, workout in
            let template = templates.first { $0.serverId == workout.templateServerId } ?? workout.template
            let names = candidateNames(workout: workout, template: template, index: index)

            let state: WorkoutTileState
            let date: Date
            if index == currentIndex {
                state = .next
                date = anchor
            } else if let match = pool.firstIndex(where: { names.contains(normalized($0.workoutTemplate)) }) {
                state = .done
                date = pool.remove(at: match).date
            } else {
                state = .later
                // Project onto the calendar around the up-next day: rows below the up-next row read as
                // the following days, rows above it as the preceding days (the slot they had this cycle).
                let offset = index - currentIndex
                date = calendar.date(byAdding: .day, value: offset, to: anchor) ?? anchor
            }

            return RotationRow(
                id: workout.id,
                index: index,
                workout: workout,
                template: template,
                state: state,
                weekday: VoidFormat.weekday(date, calendar: calendar),
                date: date
            )
        }
    }

    /// Names a completed workout might have been logged under for this rotation day.
    /// - Parameter index: 0-based position in the rotation; an unnamed day is logged as "DAY 02"
    ///   (see `RotationRow.word` / `TodayViewModel.word`).
    static func candidateNames(workout: ProgramWorkout, template: Template?, index: Int) -> Set<String> {
        var names = Set<String>()
        if let template, !template.name.isEmpty { names.insert(normalized(template.name)) }
        if let label = workout.dayLabel, !label.isEmpty { names.insert(normalized(label)) }
        names.insert(normalized(workout.displayName))
        names.insert(normalized("DAY \(VoidFormat.pad2(index + 1))"))
        names.insert(normalized("DAY \(VoidFormat.pad2(workout.dayNumber + 1))"))
        return names
    }

    static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
