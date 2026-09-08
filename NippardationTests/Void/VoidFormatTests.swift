//
//  VoidFormatTests.swift
//  NippardationTests
//

import Testing
import Foundation
@testable import Nippardation

@Suite("VoidFormat")
struct VoidFormatTests {

    @Test func padsCountsToTwoDigits() {
        #expect(VoidFormat.pad2(0) == "00")
        #expect(VoidFormat.pad2(2) == "02")
        #expect(VoidFormat.pad2(12) == "12")
        #expect(VoidFormat.pad2(120) == "120")
    }

    @Test func ratioPadsBothSides() {
        #expect(VoidFormat.ratio(2, 5) == "02 / 05")
        #expect(VoidFormat.ratio(12, 40) == "12 / 40")
    }

    @Test func readoutJoinsWithMiddleDot() {
        #expect(VoidFormat.readout(["DAY 02 / 05", nil, "", "THE OG"]) == "DAY 02 / 05 · THE OG")
        #expect(VoidFormat.readout([]) == "")
    }

    @Test func volumeUsesKWithOneDecimal() {
        let big = VoidFormat.volume(38_400)
        #expect(big.number == "38.4")
        #expect(big.unit == "K")

        let small = VoidFormat.volume(640)
        #expect(small.number == "640")
        #expect(small.unit == nil)

        let zero = VoidFormat.volume(0)
        #expect(zero.number == "0")
    }

    @Test func deltasCarryArrows() {
        #expect(VoidFormat.deltaPercent(6) == "↑ 6%")
        #expect(VoidFormat.deltaPercent(-3) == "↓ 3%")
        #expect(VoidFormat.deltaPercent(0) == "→ 0%")
        #expect(VoidFormat.deltaValue(-0.6) == "↓ 0.6")
        #expect(VoidFormat.deltaValue(1.26) == "↑ 1.3")
        #expect(VoidFormat.weight(182.44) == "182.4")
    }

    @Test func dateEyebrowReadsWeekdayAndMonthDay() {
        let calendar = VoidFixtures.calendar
        let tuesday = VoidFixtures.date(2026, 9, 8)
        #expect(VoidFormat.dateEyebrow(tuesday, calendar: calendar) == "TUE · 09.08")
        #expect(VoidFormat.weekday(VoidFixtures.date(2026, 9, 13), calendar: calendar) == "SUN")
        #expect(VoidFormat.monthDay(VoidFixtures.date(2026, 12, 25), calendar: calendar) == "12.25")
    }

    @Test func countReadouts() {
        #expect(VoidFormat.exercises(6) == "06 EXERCISES")
        #expect(VoidFormat.exercises(1) == "01 EXERCISE")
        #expect(VoidFormat.minutes(55) == "~55 MIN")
        #expect(VoidFormat.days(4) == "4 DAYS")
        #expect(VoidFormat.days(1) == "1 DAY")
        #expect(VoidFormat.weeks(8) == "8 WEEKS")
    }

    @Test func relativeDay() {
        let calendar = VoidFixtures.calendar
        let now = VoidFixtures.now
        #expect(VoidFormat.relativeDay(now, now: now, calendar: calendar) == "today")
        #expect(VoidFormat.relativeDay(VoidFixtures.daysAgo(1), now: now, calendar: calendar) == "yesterday")
        #expect(VoidFormat.relativeDay(VoidFixtures.date(2026, 8, 30), now: now, calendar: calendar) == "Aug 30")
        #expect(VoidFormat.relativeDay(VoidFixtures.date(2025, 8, 30), now: now, calendar: calendar) == "Aug 30, 2025")
    }

    @Test func initials() {
        #expect(VoidFormat.initials("The OG") == "TO")
        #expect(VoidFormat.initials("Marcus") == "M")
        #expect(VoidFormat.initials("Upper / Lower") == "UL")
        #expect(VoidFormat.initials("") == "?")
    }
}
