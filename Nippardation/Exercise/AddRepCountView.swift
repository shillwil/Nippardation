//
//  AddRepCountView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//
//  "Add set" sheet: a system form under a navigation bar (Cancel / Save). Set type, reps and
//  weight are all entered here with the rows in `SetEntryForm.swift`; weight is typed on the
//  decimal pad or stepped in place, with no separate weight sheet. Opens on the last set type
//  logged for this exercise, with the last weight and reps logged for that type.
//

import SwiftUI

struct AddRepCountView: View {
    @State private var reps: Int
    @State private var weight: Double
    @State private var setType: SetType = .warmup
    @Environment(\.dismiss) var dismiss
    var onSave: (TrackedSet) -> Void
    @State private var exercise: Exercise
    @State private var weightString: String = ""
    @FocusState private var isWeightFocused: Bool
    
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
        // The memory for the type the sheet opens on: `onChange(of: setType)` doesn't run for
        // the initial value, so a Working opening would otherwise show the warm-up numbers.
        let rememberedReps = initialSetType == .working ? defaultWorkingReps : defaultWarmupReps
        let rememberedWeight = initialSetType == .working ? defaultWorkingWeight : defaultWarmupWeight
        let initialReps: Int = rememberedReps > 0 ? rememberedReps : exercise.reps.lowerBound
        let initialWeight: Double = rememberedWeight > 0 ? rememberedWeight : 45.0
        
        _reps = State(initialValue: initialReps)
        _weight = State(initialValue: initialWeight)
        _setType = State(initialValue: initialSetType)
        _weightString = State(initialValue: SetEntry.weightText(initialWeight))
        
        _lastWorkingWeight = AppStorage(wrappedValue: defaultWorkingWeight, workingKey)
        _lastWarmupWeight = AppStorage(wrappedValue: defaultWarmupWeight, warmupKey)
        _lastWorkingReps = AppStorage(wrappedValue: defaultWorkingReps, workingRepsKey)
        _lastWarmupReps = AppStorage(wrappedValue: defaultWarmupReps, warmupRepsKey)
        _lastSetType = AppStorage(wrappedValue: savedSetType, setTypeKey)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // The exercise, as a title above the form's cards.
                Section {
                    Text(exercise.type.name)
                        .font(VoidFont.title)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(2)
                        .accessibilityAddTraits(.isHeader)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    SetTypePicker(setType: $setType)
                    SetRepsStepper(reps: $reps)
                } footer: {
                    Text(targetReadout)
                }

                SetWeightSection(weight: $weight, text: $weightString, isFocused: $isWeightFocused)
            }
            .listSectionSpacing(.compact)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // Dismissing throws the entry away, so this is Cancel rather than Close.
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSet()
                    }
                    .disabled(!canSave)
                }
                // The decimal pad has no return key.
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isWeightFocused = false
                    }
                }
            }
            .onChange(of: setType) { oldValue, newValue in
                // Update values based on set type
                if newValue == .warmup {
                    // Switch to warmup values
                    if lastWarmupWeight > 0 {
                        weight = lastWarmupWeight
                        weightString = SetEntry.weightText(lastWarmupWeight)
                    }
                    if lastWarmupReps > 0 {
                        reps = lastWarmupReps
                    }
                } else if newValue == .working {
                    // Switch to working values
                    if lastWorkingWeight > 0 {
                        weight = lastWorkingWeight
                        weightString = SetEntry.weightText(lastWorkingWeight)
                    }
                    if lastWorkingReps > 0 {
                        reps = lastWorkingReps
                    }
                }
            }
        }
        .tint(VoidColor.plasmaInk)
    }

    private var targetReadout: String {
        "Target \(VoidFormat.pad2(exercise.reps.lowerBound)) – \(VoidFormat.pad2(exercise.reps.upperBound)) reps"
    }
    
    /// Save stays off until there's a weight in range to save.
    private var canSave: Bool {
        SetEntry.weightToSave(text: weightString, weight: weight) != nil
    }

    /// The typed weight is read here, not on focus loss, so a number still being typed is kept.
    /// A remembered or stepped weight the text still shows is saved as it is, unrounded.
    private func saveSet() {
        guard let enteredWeight = SetEntry.weightToSave(text: weightString, weight: weight) else { return }
        isWeightFocused = false
        weight = enteredWeight

        // Save the weight for this exercise and set type
        if setType == .working {
            lastWorkingWeight = enteredWeight
            lastWorkingReps = reps
        } else {
            lastWarmupWeight = enteredWeight
            lastWarmupReps = reps
        }
    
        // Save the last used set type
        lastSetType = setType == .warmup ? "warmup" : "working"
    
        // Create tracked set and save
        let trackedSet = TrackedSet(reps: reps, weight: enteredWeight, setType: setType, exerciseType: exercise.type)
        onSave(trackedSet)
        dismiss()
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
