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
