//
//  ExercisesListView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//

import SwiftUI

struct ExercisesListView: View {
    var workout: Workout
    @State private var showingExerciseDetail = false
    @State private var selectedExerciseIndex: Int?
    
    var body: some View {
        List {
            ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, exercise in
                Button {
                    selectedExerciseIndex = index
                    showingExerciseDetail = true
                } label: {
                    HStack {
                        Text(exercise.type.name)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(workout.name)
        .sheet(isPresented: $showingExerciseDetail) {
            if let index = selectedExerciseIndex {
                ActiveExerciseDetailView(
                    workout: .constant(createReadOnlyWorkout()),
                    showingExerciseDetail: $showingExerciseDetail,
                    exerciseIndex: index,
                    isReadOnly: true
                )
            }
        }
    }
    
    private func createReadOnlyWorkout() -> TrackedWorkout {
        let trackedExercises = workout.exercises.map { exercise in
            TrackedExercise(
                exerciseName: exercise.type.name,
                muscleGroups: exercise.type.muscleGroup.map { $0.rawValue },
                trackedSets: []
            )
        }
        
        return TrackedWorkout(
            date: Date(),
            workoutTemplate: workout.name,
            trackedExercises: trackedExercises
        )
    }
}

//#Preview {
//    ExercisesListView(workout: .constant(mondayWorkout))
//}
