//
//  AIGeneratingView.swift
//  Nippardation
//
//  The screen shown while the AI generates a plan: a system spinner, the rotating status message
//  and Cancel, on the hull. It replaces the whole wizard while it is up rather than dimming it.
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
        VStack(spacing: VoidSpace.s6) {
            ProgressView {
                Text("Generating").voidEyebrow()
            }
            .controlSize(.large)
            .tint(VoidColor.plasma)

            Text(message)
                .font(VoidFont.body)
                .foregroundStyle(VoidColor.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .animation(.easeOut(duration: 0.12), value: messageIndex)

            Button(role: .cancel, action: onCancel) {
                Text("Cancel")
                    .frame(minWidth: 120)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(VoidColor.text)
        }
        .padding(.horizontal, VoidSpace.s6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VoidColor.hull.ignoresSafeArea())
        .accessibilityAddTraits(.isModal)
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
    AIGeneratingView(
        messageIndex: 2,
        messages: ["Analyzing your goals...", "Selecting exercises...", "Building your program..."],
        onCancel: {}
    )
}
