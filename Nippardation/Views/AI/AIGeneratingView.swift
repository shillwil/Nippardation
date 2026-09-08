//
//  AIGeneratingView.swift
//  Nippardation
//
//  Overlay shown while the AI generates a plan: scrim + panel, eyebrow, rotating message, Cancel.
//

import SwiftUI

struct AIGeneratingView: View {
    let messageIndex: Int
    let messages: [String]
    let onCancel: () -> Void

    private var message: String {
        guard messages.indices.contains(messageIndex) else { return "" }
        return Self.onVocabulary(messages[messageIndex])
    }

    var body: some View {
        WizardBusyOverlay(eyebrow: "Generating", message: message, onCancel: onCancel)
            .animation(.easeOut(duration: 0.12), value: messageIndex)
            .transition(.opacity)
    }

    /// The view model's status strings predate the plan / workout vocabulary and end in "...";
    /// keep what is shown on-vocabulary and without the trailing dots.
    private static func onVocabulary(_ text: String) -> String {
        var result = text
            .replacingOccurrences(of: "program", with: "plan")
            .replacingOccurrences(of: "Program", with: "Plan")
            .replacingOccurrences(of: "template", with: "workout")
            .replacingOccurrences(of: "Template", with: "Workout")
        while result.hasSuffix(".") {
            result.removeLast()
        }
        return result
    }
}

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        AIGeneratingView(
            messageIndex: 2,
            messages: ["Analyzing your goals...", "Selecting exercises...", "Building your program..."],
            onCancel: {}
        )
    }
}
