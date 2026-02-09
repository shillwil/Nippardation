//
//  StepIndicator.swift
//  Nippardation
//
//  Dot-based step indicator for the program wizard
//

import SwiftUI

struct StepIndicator: View {
    let totalSteps: Int
    let currentStep: Int

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.appTheme : Color.secondary.opacity(0.3))
                    .frame(width: step == currentStep ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: currentStep)
            }
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        StepIndicator(totalSteps: 3, currentStep: 0)
        StepIndicator(totalSteps: 3, currentStep: 1)
        StepIndicator(totalSteps: 3, currentStep: 2)
    }
}
