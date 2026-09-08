//
//  VoidFontsTests.swift
//  NippardationTests
//
//  Guards the bundled fonts: if a TTF goes missing or UIAppFonts drifts, Michroma / Chakra Petch
//  silently fall back to the system font and the whole Void type system disappears.
//

import Testing
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

    @Test func infoPlistListsBothFonts() {
        let fonts = Bundle(for: WorkoutManager.self).object(forInfoDictionaryKey: "UIAppFonts") as? [String] ?? []
        #expect(fonts.contains("Michroma-Regular.ttf"))
        #expect(fonts.contains("ChakraPetch-SemiBold.ttf"))
    }

    @Test func recessURLSchemeIsRegistered() {
        let types = Bundle(for: WorkoutManager.self).object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        #expect(schemes.contains("recess"))
        #expect(schemes.contains("nippardation"))
    }
}
