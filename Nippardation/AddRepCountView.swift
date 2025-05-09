//
//  AddRepCountView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//

import SwiftUI

struct AddRepCountView: View {
    @State private var value: Int
    @Environment(\.dismiss) var dismiss
    var onSave: (TrackedSet) -> Void
    @State private var exercise: Exercise
    
    init(exercise: Exercise, onSave: @escaping (TrackedSet) -> Void) {
        _value = State(initialValue: exercise.workingSets)
        _exercise = State(initialValue: exercise)
        self.onSave = onSave
        
    }
    
    var body: some View {
        VStack {
            Button {
                dismiss()
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color(uiColor: .systemGray))
                }
            }
            Text("\(value)")
                .font(.system(size: 96, weight: .bold))
            
            Stepper("Reps Completed", value: $value)
            
            Spacer()
            
            Button {
                // Add Save Rep Action Here
                let trackedSet = TrackedSet(reps: value, exerciseType: exercise.type)
                onSave(trackedSet)
                dismiss()
            } label: {
                Text("Save")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(16)
                    .padding(.vertical)
            }
        }
        .padding()
    }
}

#Preview {
    
    AddRepCountView(exercise: Exercise(
        type: ExerciseType(name: "Neutral-Grip Lat Pulldown", muscleGroup: [.back, .biceps], dayAssociation: [.wednesday]),
        example: """
                <iframe width="560" height="315" src="https://www.youtube.com/embed/lA4_1F9EAFU?si=cXDvOvhQYxFLdnwu" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                """,
        lastSetIntensityTechnique: "Failure",
        warmUpSets: 2,
        workingSets: 2,
        reps: 8...10,
        rest: 2...3,
        trackedSets: []
    ), onSave: {_ in })
}
