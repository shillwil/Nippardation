//
//  ContentView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel = HomeViewModel()
    @State private var generalInfo: [String] = [
        "Exercise-Specific Warm-Up",
        "Workbook 1",
        "Workbook 2"
    ]
    var body: some View {
        NavigationStack {
            List {
                Section("Workouts") {
                    ForEach(viewModel.workouts, id: \.self) { workout in
                        NavigationLink {
                            ExercisesListView(workout: workout)
                        } label: {
                            Text(workout.name)
                        }
                    }
                }
                Section("General Info") {
                    
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
