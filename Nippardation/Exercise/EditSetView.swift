//
//  EditSetView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/16/25.
//
//  "Edit set" sheet: panel chrome, eyebrow title, panel-2 stepper wells, one plasma CTA.
//

import SwiftUI

// Edit Set View for modifying existing sets
struct EditSetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var reps: Int
    @Binding var weight: Double
    @Binding var setType: SetType
    var onSave: (Int, Double, SetType) -> Void
    
    @State private var weightString: String = ""
    @State private var showingWeightPicker = false
    
    init(reps: Binding<Int>, weight: Binding<Double>, setType: Binding<SetType>, onSave: @escaping (Int, Double, SetType) -> Void) {
        self._reps = reps
        self._weight = weight
        self._setType = setType
        self.onSave = onSave
        self._weightString = State(initialValue: String(format: "%.1f", weight.wrappedValue))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            LoggerSheetHeader(title: "Edit set") {
                LoggerCloseButton(accessibilityLabel: "Cancel") {
                    dismiss()
                }
            }

            VStack(alignment: .leading, spacing: VoidSpace.s4) {
                // Reps section
                VStack(alignment: .leading, spacing: 6) {
                    LoggerFieldLabel(title: "Reps")
                    LoggerStepperWell(
                        value: VoidFormat.pad2(reps),
                        unit: "reps",
                        decrementLabel: "One rep fewer",
                        incrementLabel: "One rep more",
                        onDecrement: {
                            if reps > 1 {
                                reps -= 1
                            }
                        },
                        onIncrement: {
                            reps += 1
                        }
                    )
                }

                // Set type
                VStack(alignment: .leading, spacing: 6) {
                    LoggerFieldLabel(title: "Set type")
                    LoggerSegmentedControl(
                        items: [SetType.warmup, SetType.working],
                        label: { $0 == .warmup ? "Warm-up" : "Working" },
                        selection: $setType
                    )
                }

                // Weight section
                VStack(alignment: .leading, spacing: 6) {
                    LoggerFieldLabel(title: "Weight · lbs")
                    LoggerValueWell(
                        value: String(format: "%.1f", weight),
                        unit: "lbs",
                        accessibilityLabel: "Weight, opens the weight entry"
                    ) {
                        showingWeightPicker = true
                    }
                }
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.top, VoidSpace.s2)

            Spacer(minLength: VoidSpace.s4)

            // Save button
            VoidCTAButton(title: "Save set") {
                onSave(reps, weight, setType)
                dismiss()
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.bottom, VoidSpace.s3)
        }
        .background(VoidColor.panel.ignoresSafeArea())
        .sheet(isPresented: $showingWeightPicker) {
            WeightInputView(weight: $weight, weightString: $weightString)
                .presentationDetents([.fraction(0.667)])
                .voidSheet()
        }
    }
}

#Preview {
    EditSetView(reps: .constant(8), weight: .constant(42.5), setType: .constant(.working)) { _, _,_  in
        
    }
}
