//
//  NavigationLargeTitleTests.swift
//  NippardationTests
//
//  Large titles follow the text size the way the system's own do: 34pt at the default size,
//  and still growing at the accessibility sizes. Inside the bar's large-title slot, SwiftUI
//  would stop the Plan tab's wrapping title at xxLarge, so it sizes itself from this curve.
//

import Testing
import SwiftUI
import UIKit
@testable import Nippardation

@Suite("Navigation large title size")
struct NavigationLargeTitleTests {

    @Test func isTheDesignSizeAtTheDefaultTextSize() {
        #expect(abs(VoidFont.navLargeTitleSize(at: .large) - VoidFont.navLargeTitleSize) < 0.01)
    }

    @Test func keepsGrowingThroughTheAccessibilitySizes() {
        let sizes = DynamicTypeSize.allCases.map { VoidFont.navLargeTitleSize(at: $0) }

        #expect(sizes == sizes.sorted())
        #expect(VoidFont.navLargeTitleSize(at: .accessibility5) > VoidFont.navLargeTitleSize(at: .xxLarge) * 1.5)
    }

    /// NippardationApp scales the bar's own large-title font; the Plan tab's title must agree.
    @Test func matchesTheBarsLargeTitleFontAtEverySize() throws {
        let base = try #require(UIFont(name: VoidFont.labelFontName, size: VoidFont.navLargeTitleSize))
        for size in DynamicTypeSize.allCases {
            let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(size))
            let barFont = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: base, compatibleWith: traits)

            #expect(abs(barFont.pointSize - VoidFont.navLargeTitleSize(at: size)) < 0.5, "\(size)")
        }
    }
}
