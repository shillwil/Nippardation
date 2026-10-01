//
//  VoidPillPairTests.swift
//  NippardationTests
//
//  The pill pair sits side by side while the wider title fits in half the row, and stacks
//  otherwise, rather than squeezing the longer title into its half.
//

import Testing
import SwiftUI
import UIKit
@testable import Nippardation

@Suite("Pill pair layout")
@MainActor
struct VoidPillPairTests {

    private let long = "Preview Exercises"
    private let short = "Swap Workout"

    @Test func sitsSideBySideWhenBothTitlesFit() {
        let pill = size(VoidPillButton(title: long, action: {}).fixedSize())
        let height = size(pair, width: 2 * pill.width + 10 + 2 * VoidSpace.insetCard + 20).height

        #expect(abs(height - pill.height) < 1)
    }

    /// Wide enough for both titles in a row only if the longer one took more than its half.
    @Test func stacksRatherThanSqueezeTheLongerTitle() throws {
        let longPill = size(VoidPillButton(title: long, action: {}).fixedSize())
        let shortPill = size(VoidPillButton(title: short, action: {}).fixedSize())
        try #require(longPill.width > shortPill.width + 8)

        let bothFit = longPill.width + shortPill.width + 10
        let halvesFit = 2 * longPill.width + 10
        let height = size(pair, width: (bothFit + halvesFit) / 2 + 2 * VoidSpace.insetCard).height

        #expect(height > longPill.height * 1.5)
    }

    // MARK: - Helpers

    private var pair: some View {
        VoidPillPair(leading: long, trailing: short, onLeading: {}, onTrailing: {})
    }

    /// The size `view` takes when offered `width` (nil: as wide as it likes).
    private func size(_ view: some View, width: CGFloat? = nil) -> CGSize {
        UIHostingController(rootView: view)
            .sizeThatFits(in: CGSize(width: width ?? .greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
    }
}
