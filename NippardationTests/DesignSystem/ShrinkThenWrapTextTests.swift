//
//  ShrinkThenWrapTextTests.swift
//  NippardationTests
//
//  Exercise names and details on Edit workout and Preview Exercises shrink toward 70% to stay
//  on one line, and take a second line only when 70% isn't enough. That includes the
//  letter-spaced eyebrow style, whose spacing doesn't shrink with the glyphs.
//

import Testing
import SwiftUI
import UIKit
@testable import Nippardation

@Suite("Shrink-then-wrap text")
@MainActor
struct ShrinkThenWrapTextTests {

    private let name = "Single-Arm Cable Lateral Raise"
    private let prescription = "3 × 8–12 · 2 warm-up · 90 s rest"

    // MARK: - Names

    @Test func aNameThatFitsStaysOneLineAtFullSize() {
        let natural = size(Text(name).font(VoidFont.bodyStrong)).width
        let height = size(ShrinkThenWrapText(name).font(VoidFont.bodyStrong), width: natural + 20).height

        #expect(abs(height - lineHeight(of: Text("Ag").font(VoidFont.bodyStrong))) < 0.5)
    }

    /// SwiftUI's `lineLimit(2)` + `minimumScaleFactor(0.7)` would wrap this at full size.
    @Test func aNameThatFitsOnceShrunkStaysOnOneLine() {
        let line = lineHeight(of: Text("Ag").font(VoidFont.bodyStrong))
        let natural = size(Text(name).font(VoidFont.bodyStrong)).width
        let height = size(ShrinkThenWrapText(name).font(VoidFont.bodyStrong), width: natural * 0.8).height

        // Shrunk text reports its scaled height: one line, drawn smaller, above the floor.
        #expect(height < line)
        #expect(height > line * 0.7)
    }

    @Test func aNameThatDoesNotFitAt70PercentWraps() {
        let line = lineHeight(of: Text("Ag").font(VoidFont.bodyStrong))
        let natural = size(Text(name).font(VoidFont.bodyStrong)).width
        let height = size(ShrinkThenWrapText(name).font(VoidFont.bodyStrong), width: natural * 0.6).height

        #expect(height > line * 1.5)
    }

    // MARK: - Letter-spaced text

    /// Between the naive "70% of the natural width" and the true width at 70% (glyphs shrink,
    /// letter spacing doesn't), one line would end in "…", so the text has to wrap.
    @Test func letterSpacedTextWrapsWhenItsSpacingKeepsItFromFittingAt70Percent() throws {
        let widths = eyebrowWidths()
        let naive = widths.natural * 0.7
        let trueMinimum = widths.glyphs * 0.7 + widths.spacing
        try #require(trueMinimum - naive > 8, "expected the eyebrow's letter spacing to matter")

        let height = size(ShrinkThenWrapText(prescription).voidEyebrowSm(), width: (naive + trueMinimum) / 2).height

        #expect(height > lineHeight(of: Text("AG").voidEyebrowSm()) * 1.5)
    }

    @Test func letterSpacedTextThatFitsAt70PercentStaysOnOneLine() {
        let widths = eyebrowWidths()
        let trueMinimum = widths.glyphs * 0.7 + widths.spacing
        let height = size(ShrinkThenWrapText(prescription).voidEyebrowSm(), width: trueMinimum + 3).height

        #expect(height < lineHeight(of: Text("AG").voidEyebrowSm()) * 1.2)
    }

    // MARK: - Line breaks

    /// A note typed with Return: each part fits on one line here, but one line would show only
    /// the first.
    @Test func textWithALineBreakShowsItsSecondLine() {
        let note = "Pause on the chest\nKeep elbows tucked"
        let height = size(ShrinkThenWrapText(note).font(VoidFont.caption2), width: 400).height

        #expect(height > lineHeight(of: Text("Ag").font(VoidFont.caption2)) * 1.5)
    }

    // MARK: - Helpers

    /// The prescription in the eyebrow style, and without its letter spacing (built without a
    /// tracking modifier, so this doesn't lean on the view's own measurement).
    private func eyebrowWidths() -> (natural: CGFloat, glyphs: CGFloat, spacing: CGFloat) {
        let natural = size(Text(prescription).voidEyebrowSm()).width
        let glyphs = size(Text(prescription).font(VoidFont.eyebrowSm).textCase(.uppercase)).width
        return (natural, glyphs, natural - glyphs)
    }

    private func lineHeight(of text: some View) -> CGFloat {
        size(text).height
    }

    /// The size `view` takes when offered `width` (nil: as wide as it likes).
    private func size(_ view: some View, width: CGFloat? = nil) -> CGSize {
        UIHostingController(rootView: view)
            .sizeThatFits(in: CGSize(width: width ?? .greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
    }
}
