//
//  ContentView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel = HomeViewModel()
    @ObservedObject private var workoutManager = WorkoutManager.shared
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var startNewWorkout: Bool = false
    @State private var showActiveWorkout: Bool = false
    @State private var error: Error? = nil
    @State private var showErrorAlert: Bool = false
    
    // Add state to track if we've done initial loading
    @State private var didCheckForActiveWorkout: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        // Workout Stats Chart
                        if !workoutManager.completedWorkouts.isEmpty {
                            WorkoutStatsView()
                                .padding(.top, 8)
                        }
                        
                        // Workout Templates
                        VStack(alignment: .leading) {
                            Text("Workout Templates")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.workouts, id: \.self) { workout in
                                NavigationLink {
                                    ExercisesListView(workout: workout)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(workout.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Text("\(workout.exercises.count) exercises")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Recent Workouts Section
                        if !workoutManager.completedWorkouts.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Recent Workouts")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                
                                ForEach(workoutManager.completedWorkouts.prefix(3)) { workout in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(workout.workoutTemplate)
                                                .font(.headline)
                                            
                                            Text(workout.formattedDate)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if let duration = workout.formattedDuration {
                                            Text(duration)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        // Conditionally show either Resume or Start New Workout button
                        if workoutManager.isWorkoutInProgress {
                            Button {
                                showActiveWorkout = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise.circle")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .aspectRatio(contentMode: .fit)
                                    Text("Resume Workout")
                                }
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(radius: 2)
                            }
                        } else {
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
                                .padding()
                                .background(Color.appTheme)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(radius: 2)
                            }
                        }
                    }
                }
                .padding()
                .sheet(isPresented: $startNewWorkout) {
                    WorkoutSelectionView { workout in
                        self.showActiveWorkout = true
                    }
                }
                .fullScreenCover(isPresented: $showActiveWorkout) {
                    if let activeWorkout = workoutManager.activeWorkout {
                        NavigationStack {
                            ActiveWorkoutView(workout: activeWorkout)
                        }
                    }
                }

            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if let user = authManager.user {
                            Label(user.email ?? "User", systemImage: "person.circle")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            signOut()
                        }) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                            .foregroundColor(.appTheme)
                    }
                }
            }
            .onAppear {
                // Refresh workout data when the view appears
                workoutManager.loadCompletedWorkouts()
                
                // Check for active workout on first appear only
                if !didCheckForActiveWorkout {
                    // Explicitly force the WorkoutManager to check for cached workout
                    workoutManager.checkForActiveWorkout()
                    didCheckForActiveWorkout = true
                }
            }
        }
        
        .tint(Color.appTheme)
    }
    
    func signOut() {
        do {
            try authManager.signOut()
        } catch let authError {
            error = authError
            showErrorAlert = true
        }
    }
}

#Preview {
    HomeView()
}
