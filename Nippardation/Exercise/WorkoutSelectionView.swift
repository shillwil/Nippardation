//
//  WorkoutSelectionView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/11/25.
//

import SwiftUI

struct WorkoutSelectionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel = HomeViewModel()
    @ObservedObject var workoutManager = WorkoutManager.shared
    
    var onWorkoutSelected: (TrackedWorkout) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {            
            List {
                Section("Select a workout to begin") {}
                
                ForEach(viewModel.workouts, id: \.self) { workout in
                    Section {
                        Button {
                            startWorkout(template: workout)
                        } label: {
                            HStack {
                                Text(workout.name)
                                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.appTheme)
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .aspectRatio(contentMode: .fit)
                            }
                            .contentShape(Rectangle())
                        }
                        .tint(Color.appTheme)
                        .buttonStyle(.automatic)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Start Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                Color.appTheme
            }
        }
    }
    
    private func startWorkout(template: Workout) {
        let trackedWorkout = workoutManager.startWorkout(template: template)
        onWorkoutSelected(trackedWorkout)
        dismiss()
    }
}

#Preview {
    WorkoutSelectionView(onWorkoutSelected: { _ in })
}
