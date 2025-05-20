//
//  ActiveExerciseDetailView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/14/25.
//

import SwiftUI
import WebKit

struct ActiveExerciseDetailView: View {
    @StateObject private var viewModel: ActiveExerciseViewModel
    @ObservedObject var workoutManager = WorkoutManager.shared
    
    @Binding var workout: TrackedWorkout
    @Binding var showingExerciseDetail: Bool
    
    @State private var isShowingAddSet = false
    @State private var isEditingSet = false
    @State private var selectedSetIndex: Int?
    @State private var editingReps: Int = 0
    @State private var editingWeight: Double = 0.0
    @State private var editingSetType: SetType = .working
    @State private var showingCancelAlert = false
    
    let exerciseIndex: Int
    
    init(workout: Binding<TrackedWorkout>, showingExerciseDetail: Binding<Bool>, exerciseIndex: Int) {
        self._workout = workout
        self._showingExerciseDetail = showingExerciseDetail
        self.exerciseIndex = exerciseIndex
        
        // Create the view model with binding
        _viewModel = StateObject(wrappedValue: ActiveExerciseViewModel(
            workout: workout.wrappedValue,
            exerciseIndex: exerciseIndex
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            fullPlayerView
        }
    }
    
    // Mini player view (collapsed state)
    private var miniPlayerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentExercise.exerciseName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(viewModel.currentExercise.trackedSets.count) sets tracked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .frame(height: 80)
    }
    
    // Full player view (expanded state)
    private var fullPlayerView: some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack {
                Button {
                    if viewModel.currentExercise.trackedSets.isEmpty {
                        showingExerciseDetail = false
                    } else {
                        showingCancelAlert = true
                    }
                } label: {
                    Text("Cancel")
                        .foregroundColor(Color.appTheme)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Exercise title
                    Text(viewModel.currentExercise.exerciseName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)
                    
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
                                                    editingSetType = set.setType
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
                    
                    // Spacer to ensure bottom button doesn't overlap content
                    Spacer(minLength: 100)
                }
                .padding(.bottom, 20)
            }
            
            // "Finish This Movement" button at bottom
            VStack {
                Button {
                    saveAndClose()
                } label: {
                    Text("Finish This Movement")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appTheme)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                }
                .padding()
            }
            .background(
                Rectangle()
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -5)
            )
        }
        .alert("Cancel Exercise", isPresented: $showingCancelAlert) {
            Button("Go Back", role: .cancel) {
                // Just dismiss the alert
            }
            
            Button("Cancel Anyway", role: .destructive) {
                showingExerciseDetail = false
            }
        } message: {
            Text("You have unsaved sets for this exercise. Are you sure you want to cancel?")
        }
        .sheet(isPresented: $isShowingAddSet) {
            if let exercise = viewModel.matchingExercise {
                AddRepCountView(exercise: exercise) { newSet in
                    viewModel.addSet(newSet)
                    // Update the binding to ensure changes propagate
                    workout.trackedExercises[exerciseIndex] = viewModel.currentExercise
                }
                .presentationDetents([.fraction(0.75)])
            }
        }
        .sheet(isPresented: $isEditingSet) {
            if let index = selectedSetIndex {
                EditSetView(
                    reps: $editingReps,
                    weight: $editingWeight,
                    setType: $editingSetType,
                    onSave: { newReps, newWeight, newSetType in
                        viewModel.updateSet(at: index, reps: newReps, weight: newWeight, setType: newSetType)
                        // Update the binding to ensure changes propagate
                        workout.trackedExercises[exerciseIndex] = viewModel.currentExercise
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .onAppear {
            // Synchronize view model with the latest workout data
            viewModel.updateWorkout(workout)
        }
        .onChange(of: viewModel.workout) { newValue in
            // Keep the binding in sync with view model changes
            workout = newValue
        }
    }
    
    private func saveAndClose() {
        // Save changes through the workout binding
        workout.trackedExercises[exerciseIndex] = viewModel.currentExercise
        // Update in workout manager
        workoutManager.updateExercise(at: exerciseIndex, with: viewModel.currentExercise)
        showingExerciseDetail = false
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
                .foregroundColor(.appTheme)
            
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
        showingExerciseDetail: .constant(true),
        exerciseIndex: 0)
}
