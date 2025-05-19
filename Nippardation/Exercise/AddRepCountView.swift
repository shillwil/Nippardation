//
//  AddRepCountView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//

import SwiftUI

struct AddRepCountView: View {
    @State private var reps: Int
    @State private var weight: Double
    @State private var setType: SetType = .working
    @Environment(\.dismiss) var dismiss
    var onSave: (TrackedSet) -> Void
    @State private var exercise: Exercise
    @State private var showWeightPicker = false
    @State private var weightString: String = ""
    
    @AppStorage("lastWorkingWeight-") private var lastWorkingWeight: Double = 0.0
    @AppStorage("lastWarmupWeight-") private var lastWarmupWeight: Double = 0.0
    
    init(exercise: Exercise, onSave: @escaping (TrackedSet) -> Void) {
        _exercise = State(initialValue: exercise)
        self.onSave = onSave
        
        _reps = State(initialValue: exercise.reps.lowerBound)
        
        let exerciseKey = exercise.type.name.replacingOccurrences(of: " ", with: "_")
        let workingKey = "lastWorkingWeight-\(exerciseKey)"
        let warmupKey = "lastWarmupWeight-\(exerciseKey)"
        
        let defaultWorkingWeight = UserDefaults.standard.double(forKey: workingKey)
        let defaultWarmupWeight = UserDefaults.standard.double(forKey: warmupKey)
        
        _weight = State(initialValue: defaultWorkingWeight > 0 ? defaultWorkingWeight : 45)
        _weightString = State(initialValue: String(format: "%.1f", defaultWorkingWeight))
        
        _lastWorkingWeight = AppStorage(wrappedValue: defaultWorkingWeight, workingKey)
        _lastWarmupWeight = AppStorage(wrappedValue: defaultWarmupWeight, warmupKey)
    }
    
    var body: some View {
        VStack {
            xButton
                .padding()
            
            Text("Track Set")
                .font(.title)
                .fontWeight(.bold)
            
            // Reps section
            repsSection
                .padding()
            
            // Set type selector
            repTypePicker
            
            // Weight section
            weightSelector
                .padding(.horizontal)
            
            Spacer()
            
            // Target range info
            let targetReps = exercise.reps.lowerBound...exercise.reps.upperBound
            Text("Target: \(targetReps.lowerBound)-\(targetReps.upperBound) reps")
                .foregroundColor(.secondary)
                .padding(.bottom, 5)
            
            // Save button
            saveButton
        }
        .sheet(isPresented: $showWeightPicker) {
            WeightInputView(weight: $weight, weightString: $weightString)
                .presentationDetents([.fraction(0.667)])
        }
    }
    
    private var repsSection: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("REPS")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\(reps)")
                .font(.system(size: 80, weight: .bold))
            
            // Stepper for reps
            HStack(spacing: 24) {
                Button {
                    if reps > 1 {
                        reps -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(Color.appTheme)
                }
                
                Button {
                    reps += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(Color.appTheme)
                }
            }
            .padding(.vertical, 5)
        }
    }
    
    private var repTypePicker: some View {
        Picker("Set Type", selection: $setType) {
            Text("Warm-up").tag(SetType.warmup)
            Text("Working").tag(SetType.working)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: setType) { oldValue, newValue in
            // Update weight based on set type
            if newValue == .warmup && lastWarmupWeight > 0 {
                weight = lastWarmupWeight
                weightString = String(format: "%.1f", weight)
            } else if newValue == .working && lastWorkingWeight > 0 {
                weight = lastWorkingWeight
                weightString = String(format: "%.1f", weight)
            }
        }
    }
    
    private var weightSelector: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("WEIGHT (LBS)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button {
                showWeightPicker = true
            } label: {
                HStack {
                    Text("\(weight, specifier: "%.1f")")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            // Save the weight for this exercise and set type
            if setType == .working {
                lastWorkingWeight = weight
            } else {
                lastWarmupWeight = weight
            }
            
            // Create tracked set and save
            let trackedSet = TrackedSet(reps: reps, weight: weight, setType: setType, exerciseType: exercise.type)
            onSave(trackedSet)
            dismiss()
        } label: {
            Text("Save Set")
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.appTheme)
                .cornerRadius(16)
                .padding(.vertical)
        }
        .padding(.horizontal)
    }
    
    private var xButton: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color(uiColor: .systemGray))
            }
        }
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
