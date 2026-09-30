//
//  StepIndicator.swift
//  Nippardation
//
//  Where a wizard is up to: a system progress bar in plasma, shared by the plan wizard and the
//  AI plan wizard. VoiceOver reads it as "Step n of total".
//

import SwiftUI

struct StepIndicator: View {
    let totalSteps: Int
    /// 0-based.
    let currentStep: Int

    private var total: Int { max(totalSteps, 1) }
    private var position: Int { min(max(currentStep + 1, 1), total) }

    var body: some View {
        ProgressView(value: Double(position), total: Double(total))
            .tint(VoidColor.plasma)
            .accessibilityLabel("Progress")
            .accessibilityValue("Step \(position) of \(total)")
    }
}

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        VStack(spacing: VoidSpace.s6) {
            StepIndicator(totalSteps: 3, currentStep: 0)
            StepIndicator(totalSteps: 3, currentStep: 1)
            StepIndicator(totalSteps: 3, currentStep: 2)
        }
        .padding(VoidSpace.insetCard)
    }
}
