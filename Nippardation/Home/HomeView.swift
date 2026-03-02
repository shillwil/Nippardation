//
//  ContentView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var workoutManager = WorkoutManager.shared

    @State private var startNewWorkout: Bool = false
    @State private var showActiveWorkout: Bool = false

    // Add state to track if we've done initial loading
    @State private var didCheckForActiveWorkout: Bool = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Hero workout card
                    heroSection
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.xs)

                    // Activity stats
                    if !workoutManager.completedWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            SectionHeader(title: "This Week")
                                .padding(.horizontal, AppSpacing.md)

                            ActivityStatCards(
                                workoutsThisWeek: viewModel.workoutsThisWeek,
                                totalVolume: viewModel.totalVolumeFormatted,
                                weeklyConsistency: viewModel.weeklyConsistency
                            )
                        }
                    }

                    // Volume chart
                    if !workoutManager.completedWorkouts.isEmpty {
                        WorkoutStatsView()
                            .padding(.horizontal, AppSpacing.md)
                    }

                    // Active plan details
                    PlanDetailsSection(
                        program: viewModel.activeProgram,
                        nextWorkout: viewModel.nextWorkout
                    )
                    .padding(.horizontal, AppSpacing.md)

                    // Recent Workouts Section
                    if !workoutManager.completedWorkouts.isEmpty {
                        recentWorkoutsSection
                            .padding(.horizontal, AppSpacing.md)
                    }

                    Spacer(minLength: 100)
                }
            }

            // FAB overlay
            VStack {
                Spacer()

                HStack {
                    Spacer()

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
                            .cornerRadius(AppCornerRadius.large)
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
                            .cornerRadius(AppCornerRadius.large)
                            .shadow(radius: 2)
                        }
                    }
                }
            }
            .padding()
            .sheet(isPresented: $startNewWorkout) {
                NavigationStack {
                    WorkoutSelectionView { workout in
                        self.showActiveWorkout = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showActiveWorkout) {
                if let activeWorkout = workoutManager.activeWorkout {
                    NavigationStack {
                        ActiveWorkoutView(workout: activeWorkout)
                    }
                } else {
                    // Fallback: dismiss if no active workout (race condition guard)
                    Color.clear.onAppear { showActiveWorkout = false }
                }
            }
        }
        .navigationTitle("Home")
        .onAppear {
            workoutManager.loadCompletedWorkouts()
            viewModel.loadDashboard()
            viewModel.computeWeeklyStats(from: workoutManager.completedWorkouts)

            if !didCheckForActiveWorkout {
                workoutManager.checkForActiveWorkout()
                didCheckForActiveWorkout = true
            }
        }
        .onChange(of: workoutManager.completedWorkouts.count) {
            viewModel.computeWeeklyStats(from: workoutManager.completedWorkouts)
        }
    }

    // MARK: - Hero Section

    @ViewBuilder
    private var heroSection: some View {
        if let program = viewModel.activeProgram {
            HeroWorkoutCard(
                workout: viewModel.nextWorkout,
                template: viewModel.nextTemplate,
                programProgress: program.progress,
                onStart: {
                    if workoutManager.isWorkoutInProgress {
                        showActiveWorkout = true
                    } else {
                        startNewWorkout = true
                    }
                }
            )
        } else {
            HeroWorkoutFallbackCard(onChooseProgram: {
                startNewWorkout = true
            })
        }
    }

    // MARK: - Recent Workouts

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Recent Workouts")

            ForEach(workoutManager.completedWorkouts.prefix(3)) { workout in
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
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
                .padding(AppSpacing.md)
                .cardStyle()
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .withDependencies(.preview)
}
