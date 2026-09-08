//
//  StepIndicator.swift
//  Nippardation
//
//  Squared 4pt step marks for the plan wizard (matches AIStepIndicator).
//

import SwiftUI

struct StepIndicator: View {
    let totalSteps: Int
    let currentStep: Int

    var body: some View {
        HStack(spacing: VoidSpace.s2) {
            ForEach(0..<totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(step <= currentStep ? VoidColor.plasma : VoidColor.track)
                    .frame(width: step == currentStep ? 24 : 8, height: 4)
                    .animation(.easeOut(duration: 0.12), value: currentStep)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep + 1) of \(totalSteps)")
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
    }
}
