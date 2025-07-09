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
    @State private var volumeUnit: VolumeUnit = .pounds
    
    let exerciseIndex: Int
    let isReadOnly: Bool
    
    init(workout: Binding<TrackedWorkout>, showingExerciseDetail: Binding<Bool>, exerciseIndex: Int, isReadOnly: Bool = false) {
        self._workout = workout
        self._showingExerciseDetail = showingExerciseDetail
        self.exerciseIndex = exerciseIndex
        self.isReadOnly = isReadOnly
        
        // Create the view model with binding
        _viewModel = StateObject(wrappedValue: ActiveExerciseViewModel(
            workout: workout.wrappedValue,
            exerciseIndex: exerciseIndex
        ))
    }
    
    var body: some View {
        workoutView
            .environmentObject(viewModel)
    }
    
    private var workoutView: some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack {
                if !isReadOnly {
                    cancelButton
                } else {
                    Button("Close") {
                        showingExerciseDetail = false
                    }
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
                        MovementInfoView(exercise: exercise)
                    } else if isReadOnly {
                        // Fallback for read-only mode when no matching exercise found
                        Text("Exercise details not available")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // Tracked Sets Section (only show if not read-only)
                    if !isReadOnly {
                        if viewModel.matchingExercise != nil {
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
                                trackedSetsView
                                    .padding(.horizontal)
                            }
                            
                                if viewModel.totalVolume > 0 {
                                    summaryView
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    // Spacer to ensure bottom button doesn't overlap content
                    Spacer(minLength: 100)
                }
                .padding(.bottom, 20)
            }
            
            if !isReadOnly {
                saveAndCloseButtonSection
            }
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
    
    private var saveAndCloseButtonSection: some View {
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
    
    private func saveAndClose() {
        // Save changes through the workout binding
        workout.trackedExercises[exerciseIndex] = viewModel.currentExercise
        // Update in workout manager
        workoutManager.updateExercise(at: exerciseIndex, with: viewModel.currentExercise)
        showingExerciseDetail = false
    }
    
    private var cancelButton: some View {
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
    }
    
    private var summaryView: some View {
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
                    value: formatVolume(viewModel.totalVolume),
                    icon: "chart.bar.fill"
                )
                .onTapGesture {
                    volumeUnit = volumeUnit.next()
                }
                
                Spacer()
            }
        }
    }
    
    private var trackedSetsView: some View {
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
                    
                    // Edit and Delete buttons (only show if not read-only)
                    if !isReadOnly {
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
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
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
                .lineLimit(2)
                .minimumScaleFactor(0.43)
                .scaledToFit()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let convertedVolume = volumeUnit.convert(volume, from: .pounds)
        return volumeUnit.format(convertedVolume)
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
