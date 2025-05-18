//
//  ActiveWorkoutView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/14/25.
//

import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workoutManager = WorkoutManager.shared
    @State var workout: TrackedWorkout
    
    @State private var showingEndWorkoutAlert = false
    @State private var showingExerciseDetail = false
    @State private var sheetState: SheetState = .dismissed
    @State private var selectedExerciseIndex: Int?
    
    // Timer for workout duration
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    // Stats
    @State private var totalVolume: Double = 0
    @State private var completedSets: Int = 0
    
    var body: some View {
        List {
            // Workout summary section
            Section {
                VStack(spacing: 16) {
                    // Duration and start time row
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Duration")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(formattedElapsedTime)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(workout.startTime?.formatted(date: .omitted, time: .shortened) ?? "")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    // Progress bar and stats
                    if completedSets > 0 {
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Completed Sets")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(completedSets)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Volume")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(Int(totalVolume)) lbs")
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
                ForEach(Array(zip(workout.trackedExercises.indices, workout.trackedExercises)), id: \.0) { index, exercise in
                    Button {
                        selectedExerciseIndex = index
                        showingExerciseDetail = true
                        sheetState = .expanded
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
                Button(role: .destructive) {
                    showingEndWorkoutAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("End Workout")
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(workout.workoutTemplate)
        .navigationBarTitleDisplayMode(.inline)
        .bottomSheet(isPresented: $showingExerciseDetail, sheetState: $sheetState) {
            if let index = selectedExerciseIndex {
                ActiveExerciseDetailView(
                    workout: $workout,
                    showingExerciseDetail: $showingExerciseDetail,
                    sheetState: $sheetState,
                    exerciseIndex: index
                )
            }
        }
        .alert("End Workout", isPresented: $showingEndWorkoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("End Workout", role: .destructive) {
                endWorkout()
            }
        } message: {
            Text("Are you sure you want to end this workout? Your progress will be saved.")
        }
        .onAppear {
            startTimer()
            
            // Update elapsed time based on workout start time
            if let startTime = workout.startTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
            
            // Calculate initial stats
            updateWorkoutStats()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: workout) { _, _ in
            updateWorkoutStats()
        }
    }
    
    private var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func updateWorkoutStats() {
        // Calculate total volume
        totalVolume = workout.trackedExercises.reduce(0.0) { exerciseSum, exercise in
            exerciseSum + exercise.trackedSets.reduce(0.0) { setSum, set in
                setSum + (Double(set.reps) * set.weight)
            }
        }
        
        // Count completed sets
        completedSets = workout.trackedExercises.reduce(0) { $0 + $1.trackedSets.count }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func endWorkout() {
        workoutManager.endWorkout()
        dismiss()
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
