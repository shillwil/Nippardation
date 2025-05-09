//
//  ExercisesListView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//

import SwiftUI

struct ExercisesListView: View {
    var workout: Workout
    var body: some View {
        List {
            ForEach(workout.exercises) { exercise in
                NavigationLink {
                    ExerciseDetailView(exercise: Binding<Exercise>(get: { exercise }, set: { _ in }))
                } label: {
                    Text(exercise.type.name)
                }

            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(workout.name)
    }
}

//#Preview {
//    ExercisesListView(workout: .constant(mondayWorkout))
//}
