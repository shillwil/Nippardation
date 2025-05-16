//
//  ActiveExerciseDetailView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/14/25.
//

import SwiftUI
import WebKit

struct ActiveExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ActiveExerciseViewModel
    
    @State private var isShowingAddSet = false
    @State private var isEditingSet = false
    @State private var selectedSetIndex: Int?
    @State private var editingReps: Int = 0
    @State private var editingWeight: Double = 0.0
    
    init(workout: Binding<TrackedWorkout>, exerciseIndex: Int) {
        // Create the view model with binding
        _viewModel = StateObject(wrappedValue: ActiveExerciseViewModel(
            workout: workout.wrappedValue,
            exerciseIndex: exerciseIndex
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Exercise Information
                    if let exercise = viewModel.matchingExercise {
                        Group {
                            // Target information
                            VStack(alignment: .leading, spacing: 12) {
                                targetInfoRow(title: "Target Sets", value: "\(exercise.warmUpSets) warm-up + \(exercise.workingSets) working")
                                targetInfoRow(title: "Target Reps", value: "\(exercise.reps.lowerBound)-\(exercise.reps.upperBound)")
                                targetInfoRow(title: "Rest Period", value: "\(exercise.rest.lowerBound)-\(exercise.rest.upperBound) min")
                                targetInfoRow(title: "Intensity Technique", value: exercise.lastSetIntensityTechnique)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Example video
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Example")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                if let webView = viewModel.webView {
                                    WebViewRepresentable(webView: webView)
                                        .aspectRatio(1.8, contentMode: .fit)
                                        .cornerRadius(12)
                                        .frame(height: 200)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Tracked Sets Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Tracked Sets")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button {
                                    isShowingAddSet = true
                                } label: {
                                    Label("Add Set", systemImage: "plus.circle.fill")
                                        .font(.subheadline)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal)
                            
                            // Add a debug Text element to check if sets are tracked
                            Text("Sets count: \(viewModel.currentExercise.trackedSets.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            if viewModel.currentExercise.trackedSets.isEmpty {
                                Text("No sets tracked yet")
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(Array(zip(viewModel.currentExercise.trackedSets.indices, viewModel.currentExercise.trackedSets)), id: \.0) { index, set in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(set.setType == .warmup ? "Warm-up Set" : "Working Set")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                
                                                Text("Set \(index + 1)")
                                                    .font(.headline)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("\(set.reps) reps")
                                                    .font(.headline)
                                                
                                                Text("\(Int(set.weight)) lbs")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            // Edit and Delete buttons
                                            Menu {
                                                Button {
                                                    selectedSetIndex = index
                                                    editingReps = set.reps
                                                    editingWeight = set.weight
                                                    isEditingSet = true
                                                } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                
                                                Button(role: .destructive) {
                                                    viewModel.deleteSet(at: index)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            } label: {
                                                Image(systemName: "ellipsis.circle")
                                                    .font(.title3)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Volume Summary
                            if viewModel.totalVolume > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Summary")
                                        .font(.headline)
                                    
                                    HStack {
                                        Spacer()
                                        
                                        volumeStatView(
                                            title: "Sets",
                                            value: "\(viewModel.currentExercise.trackedSets.count)",
                                            icon: "number.square.fill"
                                        )
                                        
                                        Spacer()
                                        
                                        volumeStatView(
                                            title: "Reps",
                                            value: "\(viewModel.totalReps)",
                                            icon: "repeat.circle.fill"
                                        )
                                        
                                        Spacer()
                                        
                                        volumeStatView(
                                            title: "Volume",
                                            value: "\(Int(viewModel.totalVolume))",
                                            icon: "chart.bar.fill"
                                        )
                                        
                                        Spacer()
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle(viewModel.currentExercise.exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSet) {
                if let exercise = viewModel.matchingExercise {
                    AddRepCountView(exercise: exercise) { newSet in
                        viewModel.addSet(newSet)
                    }
                    .presentationDetents([.fraction(0.75)])
                }
            }
            .sheet(isPresented: $isEditingSet) {
                if let index = selectedSetIndex {
                    EditSetView(
                        reps: $editingReps,
                        weight: $editingWeight,
                        onSave: { newReps, newWeight in
                            viewModel.updateSet(at: index, reps: newReps, weight: newWeight)
                        }
                    )
                    .presentationDetents([.medium])
                }
            }
        }
    }
    
    @ViewBuilder
    private func targetInfoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    @ViewBuilder
    private func volumeStatView(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
    }
}

#Preview {
    ActiveExerciseDetailView(
        workout: .constant(TrackedWorkout(
            date: Date(),
            workoutTemplate: "Pull Day (Hypertrophy Focus)",
            trackedExercises: [
                TrackedExercise(
                    exerciseName: "Test Exercise",
                    muscleGroups: [MuscleGroup.shoulders.rawValue],
                    trackedSets: [
                        TrackedSet(reps: 8, weight: 32.5, setType: .warmup, exerciseType: ExerciseType(name: "EZ Bar Curl", muscleGroup: [.biceps]))
                    ]
                )
            ])
        ),
        exerciseIndex: 0)
}
