//
//  ActiveWorkoutView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/14/25.
//

import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ActiveWorkoutViewModel
    
    // UI state properties
    @State private var showingExerciseDetail = false
    @State private var selectedExerciseIndex: Int?
    
    init(workout: TrackedWorkout) {
        // Initialize the view model with the workout
        _viewModel = StateObject(wrappedValue: ActiveWorkoutViewModel(workout: workout))
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    // Duration and start time row
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Duration")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.formattedElapsedTime)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.workout.startTime?.formatted(date: .omitted, time: .shortened) ?? "")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    // Progress bar and stats
                    if viewModel.completedSets > 0 {
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Completed Sets")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(viewModel.completedSets)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Volume")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(Int(viewModel.totalVolume)) lbs")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Exercises section
            Section("Exercises") {
                ForEach(Array(zip(viewModel.workout.trackedExercises.indices, viewModel.workout.trackedExercises)), id: \.0) { index, exercise in
                    Button {
                        selectedExerciseIndex = index
                        showingExerciseDetail = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.exerciseName)
                                    .foregroundColor(.primary)
                                
                                if exercise.trackedSets.isEmpty {
                                    Text("No sets recorded")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    let setInfo = exercise.trackedSets.count == 1 ? "1 set" : "\(exercise.trackedSets.count) sets"
                                    let exerciseVolume = exercise.trackedSets.reduce(0.0) { $0 + (Double($1.reps) * $1.weight) }
                                    
                                    Text("\(setInfo) • \(Int(exerciseVolume)) lbs")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if !exercise.trackedSets.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.subheadline)
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            
            // End workout button
            Section {
                // In ActiveWorkoutView where you handle ending the workout:
                Button("End Workout", role: .destructive) {
                    viewModel.endWorkout()
                    
                    // Short delay to ensure data is saved before dismissing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(viewModel.workout.workoutTemplate)
        .navigationBarTitleDisplayMode(.inline)
        .expandablePlayer(
            isPresented: $showingExerciseDetail,
            expandedContent: {
                if let index = selectedExerciseIndex {
                    // Create a wrapper view that handles the expanded content
                    ZStack {
                        ActiveExerciseDetailView(
                            workout: $viewModel.workout,
                            showingExerciseDetail: $showingExerciseDetail,
                            exerciseIndex: index
                        )
                    }
                }
            },
            collapsedContent: {
                // Mini player view for collapsed state
                if let index = selectedExerciseIndex {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.workout.trackedExercises[index].exerciseName)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text("\(viewModel.workout.trackedExercises[index].trackedSets.count) sets tracked")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        )
        .alert("End Workout", isPresented: $viewModel.isShowingEndWorkoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("End Workout", role: .destructive) {
                viewModel.endWorkout()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to end this workout? Your progress will be saved.")
        }
        .onAppear {
            viewModel.startTimer()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }
}

#Preview {
    ActiveWorkoutView(workout: TrackedWorkout(
        date: Date(),
        workoutTemplate: "Pull Day (Hypertrophy Focus)",
        trackedExercises: [
            TrackedExercise(
                exerciseName: "TEst exercise",
                muscleGroups: [MuscleGroup.shoulders.rawValue],
                trackedSets: []
            )
        ]))
}
