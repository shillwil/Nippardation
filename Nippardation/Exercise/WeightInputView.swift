//
//  WeightInputView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/14/25.
//
//  Weight entry sheet: panel chrome, panel-2 stepper well, increment chips, custom field, one plasma CTA.
//

import SwiftUI

struct WeightInputView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var weight: Double
    @Binding var weightString: String
        
    // Step increments
    let increments: [Double] = [2.5, 5.0, 10.0, 25.0, 45.0]
    @State private var selectedIncrement: Double = 5.0
    
    var body: some View {
        VStack(spacing: 0) {
            LoggerSheetHeader(title: "Weight") {
                LoggerCloseButton(accessibilityLabel: "Close") {
                    dismiss()
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: VoidSpace.s4) {
                    // Current weight + increment/decrement
                    VStack(alignment: .leading, spacing: 6) {
                        LoggerFieldLabel(title: "Weight · lbs")
                        LoggerStepperWell(
                            value: String(format: "%.1f", weight),
                            unit: "lbs",
                            decrementLabel: "Decrease by \(incrementLabel(selectedIncrement))",
                            incrementLabel: "Increase by \(incrementLabel(selectedIncrement))",
                            onDecrement: {
                                let newWeight = max(0, weight - selectedIncrement)
                                weight = newWeight
                                weightString = String(format: "%.1f", newWeight)
                            },
                            onIncrement: {
                                let newWeight = weight + selectedIncrement
                                weight = newWeight
                                weightString = String(format: "%.1f", newWeight)
                            }
                        )
                    }

                    // Weight increment selector
                    VStack(alignment: .leading, spacing: 6) {
                        LoggerFieldLabel(title: "Adjust by")
                        LoggerSegmentedControl(
                            items: increments,
                            label: { incrementLabel($0) },
                            selection: $selectedIncrement
                        )
                    }

                    // Custom weight input
                    VStack(alignment: .leading, spacing: 6) {
                        LoggerFieldLabel(title: "Custom")
                        HStack(spacing: 10) {
                            VoidTextField(placeholder: "Enter weight", text: $weightString, keyboard: .decimalPad)
                            VoidPillButton(title: "Set") {
                                if let newWeight = Double(weightString) {
                                    weight = newWeight
                                }
                            }
                            .frame(width: 84)
                        }
                    }
                }
                .padding(.horizontal, VoidSpace.insetCard)
                .padding(.top, VoidSpace.s2)
                .padding(.bottom, VoidSpace.s5)
            }
            .scrollDismissesKeyboard(.interactively)

            VoidCTAButton(title: "Set weight") {
                commitAndDismiss()
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.bottom, VoidSpace.s3)
        }
        .background(VoidColor.panel.ignoresSafeArea())
        .onAppear {
            // Format weight string on appear
            weightString = String(format: "%.1f", weight)
        }
    }

    private func incrementLabel(_ increment: Double) -> String {
        increment == 2.5 ? "2.5" : "\(Int(increment))"
    }

    /// "Set weight" only: apply the typed custom value if it parses, then close.
    /// The header X closes without applying it (stepper edits are already live on the binding).
    private func commitAndDismiss() {
        if let newWeight = Double(weightString) {
            weight = newWeight
        }
        dismiss()
    }
}

#Preview {
    @Previewable @State var weight: Double = 45.0
    @Previewable @State var weightString: String = "45.0"
    
    WeightInputView(weight: $weight, weightString: $weightString)
}

#Preview {
    WeightInputView(weight: .constant(32.5), weightString: .constant("Yolo``"))
}
