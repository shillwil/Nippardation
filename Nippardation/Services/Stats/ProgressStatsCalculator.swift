//
//  ProgressStatsCalculator.swift
//  Nippardation
//
//  Pure calculations behind the Progress tab: streak, weekly counts, volume, PRs, plan progress.
//  Everything here is a function of (completed workouts, active plan, now) so it is unit-testable.
//

import Foundation

struct ProgressStats: Equatable {
    /// Consecutive weeks with at least one completed workout, counting back from this week.
    /// The current week counts once it has a workout; an empty current week does not break the streak.
    var streakWeeks: Int = 0
    var doneThisWeek: Int = 0
    /// Training days the active plan expects per week, nil without a plan.
    var plannedThisWeek: Int? = nil

    /// Working-set volume (weight × reps, lb) this week.
    var volumeThisWeek: Double = 0
    var volumeLastWeek: Double = 0
    /// Rounded percent change vs last week; nil when last week had no volume.
    var volumeDeltaPercent: Int? = nil

    /// Exercises whose best estimated 1RM this week beats all prior history.
    var prsThisWeek: Int = 0

    /// Workouts completed in the active plan so far (cycles × days + current index).
    var planCompletedWorkouts: Int? = nil
    /// Total workouts in the plan (weeks × days per week); nil when indefinite.
    var planTotalWorkouts: Int? = nil
    var planCurrentWeek: Int? = nil
    var planTotalWeeks: Int? = nil
    var planProgress: Double? = nil

    /// Workouts per week for the last `weeklyCounts.count` weeks, oldest first, current week last.
    var weeklyCounts: [Int] = []
    /// `weeklyCounts` divided by the weekly target, clamped to 0…1.
    var weeklyRatios: [Double] = []
}

enum ProgressStatsCalculator {

    static let chartWeeks = 8

    static func compute(
        workouts: [TrackedWorkout],
        program: Program?,
        now: Date = Date(),
        calendar: Calendar = VoidCalendar.current
    ) -> ProgressStats {
        var stats = ProgressStats()
        let completed = workouts.filter { $0.isCompleted }

        // Weekly buckets
        let thisWeek = VoidCalendar.weekInterval(offset: 0, from: now, calendar: calendar)
        let lastWeek = VoidCalendar.weekInterval(offset: 1, from: now, calendar: calendar)

        let thisWeekWorkouts = completed.filter { thisWeek.containsHalfOpen($0.date) }
        let lastWeekWorkouts = completed.filter { lastWeek.containsHalfOpen($0.date) }

        stats.doneThisWeek = thisWeekWorkouts.count
        stats.plannedThisWeek = program.map { max(1, $0.daysPerWeek) }

        // Volume
        stats.volumeThisWeek = volume(of: thisWeekWorkouts)
        stats.volumeLastWeek = volume(of: lastWeekWorkouts)
        if stats.volumeLastWeek > 0 {
            let change = (stats.volumeThisWeek - stats.volumeLastWeek) / stats.volumeLastWeek * 100
            stats.volumeDeltaPercent = Int(change.rounded())
        }

        // PRs
        stats.prsThisWeek = personalRecords(thisWeek: thisWeekWorkouts, history: completed.filter { $0.date < thisWeek.start })

        // Streak
        stats.streakWeeks = streak(completed: completed, now: now, calendar: calendar)

        // Weekly chart
        var counts: [Int] = []
        for offset in stride(from: chartWeeks - 1, through: 0, by: -1) {
            let interval = VoidCalendar.weekInterval(offset: offset, from: now, calendar: calendar)
            counts.append(completed.filter { interval.containsHalfOpen($0.date) }.count)
        }
        stats.weeklyCounts = counts
        let target = Double(stats.plannedThisWeek ?? max(counts.max() ?? 1, 1))
        stats.weeklyRatios = counts.map { min(1, Double($0) / max(target, 1)) }

        // Plan
        if let program, !program.workouts.isEmpty {
            let completedDays = program.timesCompleted * program.workouts.count + program.currentDayIndex
            stats.planCompletedWorkouts = completedDays
            let daysPerWeek = max(1, program.daysPerWeek)
            stats.planCurrentWeek = completedDays / daysPerWeek + 1
            if let weeks = program.durationWeeks, weeks > 0 {
                stats.planTotalWeeks = weeks
                stats.planTotalWorkouts = weeks * daysPerWeek
                stats.planProgress = min(1, Double(completedDays) / Double(max(1, weeks * daysPerWeek)))
                stats.planCurrentWeek = min(weeks, stats.planCurrentWeek ?? 1)
            }
        }

        return stats
    }

    // MARK: - Pieces

    /// Working-set volume in pounds. Warm-ups are excluded.
    static func volume(of workouts: [TrackedWorkout]) -> Double {
        workouts.reduce(0) { total, workout in
            total + workout.trackedExercises.reduce(0) { exerciseTotal, exercise in
                exerciseTotal + exercise.trackedSets
                    .filter { $0.setType == .working }
                    .reduce(0) { $0 + Double($1.reps) * $1.weight }
            }
        }
    }

    /// Epley estimated one-rep max.
    static func estimatedOneRepMax(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30)
    }

    /// Best e1RM per exercise name.
    static func bestLifts(in workouts: [TrackedWorkout]) -> [String: Double] {
        var best: [String: Double] = [:]
        for workout in workouts {
            for exercise in workout.trackedExercises {
                let key = exercise.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !key.isEmpty else { continue }
                for set in exercise.trackedSets where set.setType == .working {
                    let e1rm = estimatedOneRepMax(weight: set.weight, reps: set.reps)
                    if e1rm > (best[key] ?? 0) { best[key] = e1rm }
                }
            }
        }
        return best
    }

    /// Exercises whose best this week beats a prior best. First-time exercises are not counted.
    static func personalRecords(thisWeek: [TrackedWorkout], history: [TrackedWorkout]) -> Int {
        let previous = bestLifts(in: history)
        let current = bestLifts(in: thisWeek)
        return current.filter { key, value in
            guard let prior = previous[key], prior > 0 else { return false }
            return value > prior
        }.count
    }

    /// Consecutive weeks with ≥1 completed workout, counting back from this week.
    static func streak(completed: [TrackedWorkout], now: Date, calendar: Calendar) -> Int {
        guard !completed.isEmpty else { return 0 }
        var weeksWithWork = Set<Date>()
        for workout in completed {
            weeksWithWork.insert(VoidCalendar.startOfWeek(workout.date, calendar: calendar))
        }

        let thisWeekStart = VoidCalendar.startOfWeek(now, calendar: calendar)
        var cursor = thisWeekStart
        var count = 0

        // An empty current week does not break the streak; start counting from last week in that case.
        if !weeksWithWork.contains(cursor) {
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { return 0 }
            cursor = previous
        }

        while weeksWithWork.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }
}
