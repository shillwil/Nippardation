////
////  ActiveExercisesListView.swift
////  Nippardation
////
////  Created by Alex Shillingford on 5/14/25.
////
//
//import SwiftUI
//
//struct ActiveExercisesListView: View {
//    @Environment(\.dismiss) private var dismiss
//    @ObservedObject var workoutManager = WorkoutManager.shared
//    @State var workout: TrackedWorkout
//    
//    @State private var showingEndWorkoutAlert = false
//    @State private var showingExerciseDetail = false
//    @State private var selectedExerciseIndex: Int?
//    
//    // Stats
//    @State private var totalVolume: Double = 0
//    @State private var completedExercises: Int = 0
//    
//    var body: some View {
//        VStack {
//            // Exercise progress
//            VStack(spacing: 16) {
//                // Progress indicator
//                HStack {
//                    Text("Workout Progress")
//                        .font(.headline)
//                    
//                    Spacer()
//                    
//                    Text("\(completedExercises)/\(workout.trackedExercises.count) exercises")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//                
//                ProgressView(value: Double(completedExercises), total: Double(workout.trackedExercises.count))
//                    .progressViewStyle(.linear)
//                    .tint(.blue)
//            }
//            .padding(.horizontal)
//            .padding(.top)
//            
//            // Exercise list
//            List {
//                ForEach(Array(zip(workout.trackedExercises.indices, workout.trackedExercises)), id: \.0) { index, exercise in
//                    Button {
//                        selectedExerciseIndex = index
//                        showingExerciseDetail = true
//                    } label: {
//                        HStack {
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(exercise.exerciseName)
//                                    .foregroundColor(.primary)
//                                    .font(.headline)
//                                
//                                if exercise.trackedSets.isEmpty {
//                                    Text("No sets recorded")
//                                        .font(.subheadline)
//                                        .foregroundColor(.secondary)
//                                } else {
//                                    let setInfo = exercise.trackedSets.count == 1 ? "1 set" : "\(exercise.trackedSets.count) sets"
//                                    let exerciseVolume = exercise.trackedSets.reduce(0.0) { $0 + (Double($1.reps) * $1.weight) }
//                                    
//                                    Text("\(setInfo) • \(Int(exerciseVolume)) lbs")
//                                        .font(.subheadline)
//                                        .foregroundColor(.secondary)
//                                }
//                            }
//                            
//                            Spacer()
//                            
//                            if !exercise.trackedSets.isEmpty {
//                                Image(systemName: "checkmark.circle.fill")
//                                    .foregroundColor(.green)
//                                    .font(.body)
//                            }
//                            
//                            Image(systemName: "chevron.right")
//                                .foregroundColor(.secondary)
//                                .font(.caption)
//                        }
//                    }
//                }
//                
//                // End workout button
//                Section {
//                    Button(role: .destructive) {
//                        showingEndWorkoutAlert = true
//                    } label: {
//                        HStack {
//                            Spacer()
//                            Text("End Workout")
//                                .fontWeight(.bold)
//                            Spacer()
//                        }
//                    }
//                }
//            }
//        }
//        .navigationBarTitleDisplayMode(.inline)
//        .navigationTitle(workout.workoutTemplate)
//        .sheet(isPresented: $showingExerciseDetail) {
//            if let index = selectedExerciseIndex {
//                ActiveExerciseDetailView(workout: $workout, exerciseIndex: index)
//            }
//        }
//        .bottomSheet(isPresented: $showingExerciseDetail, sheetState: <#T##Binding<SheetState>#>, content: <#T##() -> View#>)
//        .alert("End Workout", isPresented: $showingEndWorkoutAlert) {
//            Button("Cancel", role: .cancel) {}
//            Button("End Workout", role: .destructive) {
//                endWorkout()
//            }
//        } message: {
//            Text("Are you sure you want to end this workout? Your progress will be saved.")
//        }
//        .onAppear {
//            updateStats()
//        }
//        .onChange(of: workout) { _, _ in
//            updateStats()
//        }
//    }
//    
//    private func updateStats() {
//        // Calculate total volume
//        totalVolume = workout.trackedExercises.reduce(0.0) { exerciseSum, exercise in
//            exerciseSum + exercise.trackedSets.reduce(0.0) { setSum, set in
//                setSum + (Double(set.reps) * set.weight)
//            }
//        }
//        
//        // Count completed exercises
//        completedExercises = workout.trackedExercises.filter { !$0.trackedSets.isEmpty }.count
//    }
//    
//    private func endWorkout() {
//        workoutManager.endWorkout()
//        dismiss()
//    }
//}
//
//#Preview {
//    ActiveExercisesListView(workout: TrackedWorkout(
//        date: Date(),
//        workoutTemplate: "Pull Day (Hypertrophy Focus)",
//        trackedExercises: [
//            TrackedExercise(
//                exerciseName: "TEst exercise",
//                muscleGroups: [MuscleGroup.shoulders.rawValue],
//                trackedSets: []
//            )
//        ]))
//}
