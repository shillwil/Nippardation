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
    
    @State private var startNewWorkout: Bool = false
    @State private var showActiveWorkout: Bool = false
    @State private var activeWorkout: TrackedWorkout?
    @ObservedObject private var workoutManager = WorkoutManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section("Workout Templates") {
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
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button {
                            startNewWorkout = true
                        } label: {
                            HStack {
                                Image(systemName: "play.circle")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .aspectRatio(contentMode: .fit)
                                Text("Start New Workout")
                            }
                        }
                        .tint(Color.appTheme)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .sheet(isPresented: $startNewWorkout) {
                    WorkoutSelectionView { workout in
                        self.activeWorkout = workout
                        self.showActiveWorkout = true
                    }
                }
                .fullScreenCover(isPresented: $showActiveWorkout) {
                    if let activeWorkout {
                        NavigationStack {
                            ActiveWorkoutView(workout: activeWorkout)
                        }
                    }
                }
                
                if workoutManager.isWorkoutInProgress {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                if let workout = workoutManager.activeWorkout {
                                    self.activeWorkout = workout
                                    self.showActiveWorkout = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Resume Workout")
                                }
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding(.bottom, 70)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Home")
        }
        .tint(Color.appTheme)
    }
}

#Preview {
    HomeView()
}
