//
//  SystemControls.swift
//  Nippardation
//
//  Thin conveniences over controls iOS provides, for the few spots where the right system
//  control depends on the OS version. Everything here renders Apple's own control.
//

import SwiftUI
import UIKit

/// The standard control for dismissing a sheet or cover without losing anything: iOS 26's
/// Liquid Glass close button (`Button(role: .close)`), and the familiar gray X before it.
/// Use `Button("Cancel", role: .cancel)` instead when dismissing throws input away.
struct SheetCloseButton: View {
    /// What VoiceOver reads when "Close" isn't specific enough (e.g. "Back to workout").
    private let accessibilityLabel: String
    private let action: () -> Void

    init(accessibilityLabel: String = "Close", action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .close, action: action)
                .accessibilityLabel(Text(accessibilityLabel))
        } else {
            Button(action: action) {
                // Palette colours, not `.secondary`, which would resolve against the plasma tint.
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color(uiColor: .secondaryLabel), Color(uiColor: .tertiarySystemFill))
                    .imageScale(.large)
            }
            .accessibilityLabel(Text(accessibilityLabel))
        }
    }
}

extension View {
    /// `navigationTitle(title)`, plus, on iOS 26, a large title that wraps onto a second line, and
    /// shrinks toward 70% only if two lines aren't enough, instead of truncating: the system's own
    /// large title is a single line. It sits in the bar's large-title slot, so it still collapses
    /// into the inline title on scroll. Before iOS 26 the system large title shows as it always has.
    func wrappingNavigationTitle(_ title: String) -> some View {
        navigationTitle(title)
            .modifier(WrappingLargeTitle(title: title))
    }
}

private struct WrappingLargeTitle: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.toolbar {
                ToolbarItem(placement: .largeTitle) {
                    Text(title)
                        // The face and size the bar's own large titles use (see NippardationApp),
                        // fixed like theirs so this one doesn't grow with the text size alone.
                        .font(.custom(VoidFont.labelFontName, fixedSize: VoidFont.navLargeTitleSize))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.leading)
                        // The slot offers one line's height: without this the title shrinks, then
                        // truncates, instead of taking its second line.
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                }
            }
        } else {
            content
        }
    }
}
