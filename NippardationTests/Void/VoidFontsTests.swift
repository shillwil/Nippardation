//
//  VoidFontsTests.swift
//  NippardationTests
//
//  Guards the bundled fonts: if a TTF goes missing or UIAppFonts drifts, Michroma / Chakra Petch
//  silently fall back to the system font and the whole Void type system disappears.
//

import Testing
import SwiftUI
import UIKit
@testable import Nippardation

@Suite("Void fonts")
struct VoidFontsTests {

    @Test func michromaIsRegistered() {
        #expect(UIFont(name: VoidFont.displayFontName, size: 44) != nil)
    }

    @Test func chakraPetchSemiBoldIsRegistered() {
        #expect(UIFont(name: VoidFont.labelFontName, size: 12) != nil)
    }

    @Test func chakraPetchRegularIsRegistered() {
        #expect(UIFont(name: VoidFont.labelFontRegular, size: 15.5) != nil)
    }

    @Test func chakraPetchMediumIsRegistered() {
        #expect(UIFont(name: VoidFont.labelFontMedium, size: 12.5) != nil)
    }

    /// The three Chakra Petch weights must share one family, otherwise `.fontWeight(...)`
    /// on a Chakra Petch run falls back to a synthesised face instead of the bundled one.
    @Test func chakraPetchWeightsShareOneFamily() {
        let families = [VoidFont.labelFontRegular, VoidFont.labelFontMedium, VoidFont.labelFontName]
            .compactMap { UIFont(name: $0, size: 15)?.familyName }
        #expect(families.count == 3)
        #expect(Set(families).count == 1)
    }

    @Test func infoPlistListsEveryBundledFont() {
        let fonts = Bundle(for: WorkoutManager.self).object(forInfoDictionaryKey: "UIAppFonts") as? [String] ?? []
        #expect(fonts.contains("Michroma-Regular.ttf"))
        #expect(fonts.contains("ChakraPetch-SemiBold.ttf"))
        #expect(fonts.contains("ChakraPetch-Medium.ttf"))
        #expect(fonts.contains("ChakraPetch-Regular.ttf"))
    }

    /// Buttons and the tab bar are the one place the Void faces do not reach. If a token
    /// here starts resolving to Chakra Petch, a control label changed face by accident.
    @Test func controlTokensStayOnTheSystemFace() {
        #expect(VoidFont.button == Font.system(size: 15, weight: .semibold))
        #expect(VoidFont.buttonLg == Font.system(size: 17, weight: .semibold))
        #expect(VoidFont.buttonSm == Font.system(size: 13, weight: .semibold))
        #expect(VoidFont.buttonPlain == Font.system(size: 15))
        #expect(VoidFont.buttonLink == Font.system(size: 13))
        #expect(VoidFont.start == Font.system(size: 20, weight: .bold))
        #expect(VoidFont.tab == Font.system(size: 10, weight: .medium))
    }

    /// Reading type is Chakra Petch, so every one of these must differ from its SF twin.
    @Test func readingTokensLeftTheSystemFace() {
        #expect(VoidFont.body != Font.system(size: 15))
        #expect(VoidFont.bodyStrong != Font.system(size: 15, weight: .semibold))
        #expect(VoidFont.caption != Font.system(size: 13))
        #expect(VoidFont.caption2 != Font.system(size: 12))
        #expect(VoidFont.title != Font.system(size: 20, weight: .bold))
        #expect(VoidFont.body == Font.custom(VoidFont.labelFontRegular, size: 15.5))
        #expect(VoidFont.bodyStrong == Font.custom(VoidFont.labelFontName, size: 15.5))
    }

    @Test func recessURLSchemeIsRegistered() {
        let types = Bundle(for: WorkoutManager.self).object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        #expect(schemes.contains("recess"))
        #expect(schemes.contains("nippardation"))
    }
}
