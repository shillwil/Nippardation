//
//  AddRepCountView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//
//  "Add set" sheet: panel chrome, eyebrow title, panel-2 stepper wells, one plasma CTA.
//

import SwiftUI

struct AddRepCountView: View {
    @State private var reps: Int
    @State private var weight: Double
    @State private var setType: SetType = .warmup
    @Environment(\.dismiss) var dismiss
    var onSave: (TrackedSet) -> Void
    @State private var exercise: Exercise
    @State private var showWeightPicker = false
    @State private var weightString: String = ""
    
    @AppStorage("lastWorkingWeight-") private var lastWorkingWeight: Double = 0.0
    @AppStorage("lastWarmupWeight-") private var lastWarmupWeight: Double = 0.0
    @AppStorage("lastWorkingReps-") private var lastWorkingReps: Int = 0
    @AppStorage("lastWarmupReps-") private var lastWarmupReps: Int = 0
    @AppStorage("lastSetType-") private var lastSetType: String = "warmup"
    
    init(exercise: Exercise, onSave: @escaping (TrackedSet) -> Void) {
        _exercise = State(initialValue: exercise)
        self.onSave = onSave
        
        _reps = State(initialValue: exercise.reps.lowerBound)
        
        let exerciseKey = exercise.type.name.replacingOccurrences(of: " ", with: "_")
        let workingKey = "lastWorkingWeight-\(exerciseKey)"
        let warmupKey = "lastWarmupWeight-\(exerciseKey)"
        let workingRepsKey = "lastWorkingReps-\(exerciseKey)"
        let warmupRepsKey = "lastWarmupReps-\(exerciseKey)"
        let setTypeKey = "lastSetType-\(exerciseKey)"
        
        let defaultWorkingWeight = UserDefaults.standard.double(forKey: workingKey)
        let defaultWarmupWeight = UserDefaults.standard.double(forKey: warmupKey)
        let defaultWorkingReps = UserDefaults.standard.integer(forKey: workingRepsKey)
        let defaultWarmupReps = UserDefaults.standard.integer(forKey: warmupRepsKey)
        let savedSetType = UserDefaults.standard.string(forKey: setTypeKey) ?? "warmup"
        
        let initialSetType: SetType = savedSetType == "warmup" ? .warmup : .working
        let initialReps: Int = defaultWarmupReps > 0 ? defaultWarmupReps : exercise.reps.lowerBound
        let initialWeight: Double = defaultWarmupWeight > 0 ? defaultWarmupWeight : 45.0
        
        _reps = State(initialValue: initialReps)
        _weight = State(initialValue: initialWeight)
        _setType = State(initialValue: initialSetType)
        _weightString = State(initialValue: String(format: "%.1f", initialWeight))
        
        _lastWorkingWeight = AppStorage(wrappedValue: defaultWorkingWeight, workingKey)
        _lastWarmupWeight = AppStorage(wrappedValue: defaultWarmupWeight, warmupKey)
        _lastWorkingReps = AppStorage(wrappedValue: defaultWorkingReps, workingRepsKey)
        _lastWarmupReps = AppStorage(wrappedValue: defaultWarmupReps, warmupRepsKey)
        _lastSetType = AppStorage(wrappedValue: savedSetType, setTypeKey)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            LoggerSheetHeader(title: "Add set") {
                LoggerCloseButton(accessibilityLabel: "Close") {
                    dismiss()
                }
            }

            VStack(alignment: .leading, spacing: VoidSpace.s4) {
                Text(exercise.type.name)
                    .font(VoidFont.title)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(2)
                    .padding(.leading, VoidSpace.insetText - VoidSpace.insetCard)

                repsSection

                repTypePicker

                weightSelector

                Text(targetReadout)
                    .voidReadout()
                    .padding(.leading, VoidSpace.insetText - VoidSpace.insetCard)
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.top, VoidSpace.s2)

            Spacer(minLength: VoidSpace.s4)

            saveButton
        }
        .background(VoidColor.panel.ignoresSafeArea())
        .sheet(isPresented: $showWeightPicker) {
            WeightInputView(weight: $weight, weightString: $weightString)
                .presentationDetents([.fraction(0.667)])
                .voidSheet()
        }
    }

    private var targetReadout: String {
        "Target \(VoidFormat.pad2(exercise.reps.lowerBound)) – \(VoidFormat.pad2(exercise.reps.upperBound)) reps"
    }
    
    private var repsSection: some View {
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
    }
    
    private var repTypePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            LoggerFieldLabel(title: "Set type")
            LoggerSegmentedControl(
                items: [SetType.warmup, SetType.working],
                label: { $0 == .warmup ? "Warm-up" : "Working" },
                selection: $setType
            )
        }
        .onChange(of: setType) { oldValue, newValue in
           // Update values based on set type
           if newValue == .warmup {
               // Switch to warmup values
               if lastWarmupWeight > 0 {
                   weight = lastWarmupWeight
                   weightString = String(format: "%.1f", weight)
               }
               if lastWarmupReps > 0 {
                   reps = lastWarmupReps
               }
           } else if newValue == .working {
               // Switch to working values
               if lastWorkingWeight > 0 {
                   weight = lastWorkingWeight
                   weightString = String(format: "%.1f", weight)
               }
               if lastWorkingReps > 0 {
                   reps = lastWorkingReps
               }
           }
       }
    }
    
    private var weightSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            LoggerFieldLabel(title: "Weight · lbs")
            LoggerValueWell(
                value: String(format: "%.1f", weight),
                unit: "lbs",
                accessibilityLabel: "Weight, opens the weight entry"
            ) {
                showWeightPicker = true
            }
        }
    }
    
    private var saveButton: some View {
        VoidCTAButton(title: "Save set") {
            // Save the weight for this exercise and set type
            if setType == .working {
                lastWorkingWeight = weight
                lastWorkingReps = reps
            } else {
                lastWarmupWeight = weight
                lastWarmupReps = reps
            }
                            
            // Save the last used set type
            lastSetType = setType == .warmup ? "warmup" : "working"
            
            // Create tracked set and save
            let trackedSet = TrackedSet(reps: reps, weight: weight, setType: setType, exerciseType: exercise.type)
            onSave(trackedSet)
            dismiss()
        }
        .padding(.horizontal, VoidSpace.insetCard)
        .padding(.bottom, VoidSpace.s3)
    }
}

#Preview {
    
    AddRepCountView(exercise: Exercise(
        type: ExerciseType(name: "Neutral-Grip Lat Pulldown", muscleGroup: [.back, .biceps]),
        example: """
                <iframe width="560" height="315" src="https://www.youtube.com/embed/lA4_1F9EAFU?si=cXDvOvhQYxFLdnwu" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                """,
        lastSetIntensityTechnique: "Failure",
        warmUpSets: 2,
        workingSets: 2,
        reps: 8...10,
        rest: 2...3,
    ), onSave: {_ in })
}
