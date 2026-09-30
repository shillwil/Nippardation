//
//  SetEntryTests.swift
//  NippardationTests
//
//  The Add set / Edit set rules: how typed weight is read (either decimal separator), the range
//  a saved weight has to sit in, weight text that reads back as the same weight, the weight a
//  Save keeps, and the step-size labels.
//

import Testing
import Foundation
@testable import Nippardation

@Suite("Set entry")
struct SetEntryTests {

    private let us = Locale(identifier: "en_US")
    private let germany = Locale(identifier: "de_DE")

    // MARK: - Reading typed weight

    @Test func readsTheRegionsDecimalComma() {
        #expect(SetEntry.weight(from: "135,5", locale: germany) == 135.5)
    }

    @Test func alwaysReadsADecimalPoint() {
        #expect(SetEntry.weight(from: "135.5", locale: us) == 135.5)
        #expect(SetEntry.weight(from: "135.5", locale: germany) == 135.5)
    }

    @Test func aCommaIsNotADecimalWhereTheRegionUsesAPoint() {
        #expect(SetEntry.weight(from: "135,5", locale: us) == nil)
    }

    @Test func readsANumberStillBeingTyped() {
        #expect(SetEntry.weight(from: "12.", locale: us) == 12)
        #expect(SetEntry.weight(from: ".5", locale: us) == 0.5)
        #expect(SetEntry.weight(from: "12,", locale: germany) == 12)
        #expect(SetEntry.weight(from: " 95 ", locale: us) == 95)
    }

    @Test func rejectsTextThatIsNotAFiniteNumber() {
        #expect(SetEntry.weight(from: "", locale: us) == nil)
        #expect(SetEntry.weight(from: ".", locale: us) == nil)
        #expect(SetEntry.weight(from: ",", locale: germany) == nil)
        #expect(SetEntry.weight(from: "abc", locale: us) == nil)
        #expect(SetEntry.weight(from: "inf", locale: us) == nil)
        #expect(SetEntry.weight(from: "nan", locale: us) == nil)
    }

    // MARK: - Range

    @Test func savesOnlyTypedWeightsInsideTheRange() {
        #expect(SetEntry.validWeight(from: "0", locale: us) == 0)
        #expect(SetEntry.validWeight(from: "2000", locale: us) == 2000)
        #expect(SetEntry.validWeight(from: "137,5", locale: germany) == 137.5)
        #expect(SetEntry.validWeight(from: "2000.1", locale: us) == nil)
        #expect(SetEntry.validWeight(from: "-5", locale: us) == nil)
        #expect(SetEntry.validWeight(from: "", locale: us) == nil)
        #expect(SetEntry.validWeight(from: ".", locale: us) == nil)
    }

    @Test func clampsIntoTheRange() {
        #expect(SetEntry.clampedWeight(-2.5) == 0)
        #expect(SetEntry.clampedWeight(2045) == 2000)
        #expect(SetEntry.clampedWeight(137.5) == 137.5)
    }

    // MARK: - Weight text

    @Test func showsOneDecimalOrTwoWhenTheWeightHasThem() {
        #expect(SetEntry.weightText(135, locale: us) == "135.0")
        #expect(SetEntry.weightText(46.2, locale: us) == "46.2")
        #expect(SetEntry.weightText(46.25, locale: us) == "46.25")
        #expect(SetEntry.weightText(2000, locale: us) == "2000.0")  // no grouping separator
    }

    @Test func showsTheRegionsDecimalSeparator() {
        #expect(SetEntry.weightText(46.25, locale: germany) == "46,25")
        #expect(SetEntry.weightText(135, locale: germany) == "135,0")
    }

    /// Regions that write their own digits still get ASCII ones, which the parser reads.
    @Test(arguments: ["ar_SA", "fa_IR", "my_MM"])
    func keepsASCIIDigitsInEveryRegion(region: String) {
        let locale = Locale(identifier: region)
        let text = SetEntry.weightText(46.25, locale: locale)
        let digitsAreASCII = text.filter(\.isNumber).allSatisfy(\.isASCII)
        #expect(digitsAreASCII)
        #expect(SetEntry.weight(from: text, locale: locale) == 46.25)
    }

    /// A set logged at 46.25 lbs (fractional plates) was rewritten as 46.2 by a Save that only
    /// changed its reps: the field showed one decimal and the text was read back.
    @Test(arguments: [46.25, 48.75, 46.75, 44.09, 137.5, 135.0, 0.0, 2000.0], ["en_US", "de_DE", "fr_FR", "ar_SA", "fa_IR"])
    func weightTextReadsBackAsTheSameWeight(weight: Double, region: String) {
        let locale = Locale(identifier: region)
        #expect(SetEntry.weight(from: SetEntry.weightText(weight, locale: locale), locale: locale) == weight)
    }

    @Test func weightTextReadsBackInTheDevicesRegion() {
        #expect(SetEntry.weight(from: SetEntry.weightText(46.25)) == 46.25)
        #expect(SetEntry.weight(from: SetEntry.weightText(48.75)) == 48.75)
    }

    /// The stepper writes its result through `weightText`: 46.25 + 2.5 stays 48.75, not 48.8.
    @Test func aSteppedWeightKeepsItsSecondDecimal() {
        let stepped = SetEntry.clampedWeight(46.25 + 2.5)
        let text = SetEntry.weightText(stepped, locale: us)
        #expect(text == "48.75")
        #expect(SetEntry.weightToSave(text: text, weight: stepped, locale: us) == 48.75)
    }

    // MARK: - Weight a Save keeps

    @Test func anUntouchedWeightIsSavedUnrounded() {
        // More decimals than the field shows: the text rounds, the save must not.
        let logged = 44.0925
        let text = SetEntry.weightText(logged, locale: us)
        #expect(text == "44.09")
        #expect(SetEntry.weightToSave(text: text, weight: logged, locale: us) == logged)
        #expect(SetEntry.weightToSave(text: SetEntry.weightText(logged, locale: germany), weight: logged, locale: germany) == logged)
    }

    @Test func aTypedWeightIsSavedAsTyped() {
        #expect(SetEntry.weightToSave(text: "50", weight: 46.25, locale: us) == 50)
        #expect(SetEntry.weightToSave(text: "47,5", weight: 46.25, locale: germany) == 47.5)
        // Typed over with a different spelling of the shown weight: the typed number wins.
        #expect(SetEntry.weightToSave(text: "44.090", weight: 44.0925, locale: us) == 44.09)
    }

    @Test func nothingToSaveWithoutAWeightInRange() {
        #expect(SetEntry.weightToSave(text: "", weight: 46.25, locale: us) == nil)
        #expect(SetEntry.weightToSave(text: ".", weight: 46.25, locale: us) == nil)
        #expect(SetEntry.weightToSave(text: "2000.1", weight: 46.25, locale: us) == nil)
        // A weight past the range isn't kept just because the field still shows it.
        #expect(SetEntry.weightToSave(text: "2500.0", weight: 2500, locale: us) == nil)
    }

    // MARK: - Step sizes

    @Test func stepSizeLabelsDropATrailingZero() {
        #expect(SetEntry.incrementLabel(2.5) == "2.5")
        #expect(SetEntry.incrementLabel(5) == "5")
        #expect(SetEntry.incrementLabel(45) == "45")
        #expect(SetEntry.weightIncrements.map(SetEntry.incrementLabel) == ["2.5", "5", "10", "25", "45"])
    }
}
