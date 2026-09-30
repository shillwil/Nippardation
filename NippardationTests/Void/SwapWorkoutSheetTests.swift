//
//  SwapWorkoutSheetTests.swift
//  NippardationTests
//
//  Where the Swap workout sheet opens: half height only while every row fits there.
//

import Testing
import SwiftUI
@testable import Nippardation

@Suite("Swap workout sheet")
@MainActor
struct SwapWorkoutSheetTests {

    private let fitting = SwapWorkoutSheet.rowsVisibleAtHalfHeight

    @Test func opensAtHalfHeightWhileEveryRowFits() {
        // One workout, Rest day and Skip workout.
        #expect(SwapWorkoutSheet.openingDetent(rowCount: 3, dynamicTypeSize: .large) == .medium)
        #expect(SwapWorkoutSheet.openingDetent(rowCount: fitting, dynamicTypeSize: .xxxLarge) == .medium)
    }

    @Test func opensAtFullHeightWhenRowsWouldStartBelowTheFold() {
        // A four-day plan: four workouts, Rest day and Skip workout.
        #expect(SwapWorkoutSheet.openingDetent(rowCount: 6, dynamicTypeSize: .large) == .large)
        #expect(SwapWorkoutSheet.openingDetent(rowCount: fitting + 1, dynamicTypeSize: .xSmall) == .large)
    }

    @Test func accessibilityTextSizesAlwaysOpenAtFullHeight() {
        #expect(SwapWorkoutSheet.openingDetent(rowCount: 2, dynamicTypeSize: .accessibility1) == .large)
        #expect(SwapWorkoutSheet.openingDetent(rowCount: 2, dynamicTypeSize: .accessibility5) == .large)
    }
}
