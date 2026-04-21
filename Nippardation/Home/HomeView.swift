//
//  ContentView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: AppTab

    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var workoutManager = WorkoutManager.shared

    @State private var startNewWorkout: Bool = false
    @State private var showActiveWorkout: Bool = false
    @State private var showNoProgramsModal: Bool = false
    @State private var showCreateProgram: Bool = false
    @State private var showAIWizard: Bool = false
    @State private var pendingModalAction: PostModalAction?

    // Add state to track if we've done initial loading
    @State private var didCheckForActiveWorkout: Bool = false

    // Tracks whether the current active workout was launched from the Hero card,
    // so we only auto-advance the program for those completions.
    @State private var startedFromHero: Bool = false

    private enum PostModalAction {
        case createManually
        case generateWithAI
        case browsePrograms
        case startFromTemplate
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Hero workout card
                    heroSection
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.xs)

                    // Exercise video previews for next workout
                    if let template = viewModel.nextTemplate, !template.exercises.isEmpty {
                        ExerciseVideoCarousel(template: template, title: "Up Next")
                    }

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
                            if viewModel.hasAnyPrograms == true {
                                startNewWorkout = true
                            } else {
                                showNoProgramsModal = true
                            }
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
            .sheet(isPresented: $showNoProgramsModal, onDismiss: {
                switch pendingModalAction {
                case .generateWithAI:
                    showAIWizard = true
                case .createManually:
                    showCreateProgram = true
                case .browsePrograms:
                    selectedTab = .programs
                case .startFromTemplate:
                    showActiveWorkout = true
                case nil:
                    break
                }
                pendingModalAction = nil
            }) {
                NoProgramsModalView(
                    templates: viewModel.userTemplates,
                    onCreateManually: {
                        pendingModalAction = .createManually
                        showNoProgramsModal = false
                    },
                    onGenerateWithAI: {
                        pendingModalAction = .generateWithAI
                        showNoProgramsModal = false
                    },
                    onBrowsePrograms: {
                        pendingModalAction = .browsePrograms
                        showNoProgramsModal = false
                    },
                    onSelectTemplate: { template in
                        startWorkoutFromTemplate(template)
                        pendingModalAction = .startFromTemplate
                        showNoProgramsModal = false
                    }
                )
                .presentationDetents(viewModel.userTemplates.isEmpty ? [.medium] : [.medium, .large])
            }
            .sheet(isPresented: $showCreateProgram) {
                NavigationStack {
                    ProgramWizardView()
                }
            }
            .fullScreenCover(isPresented: $showAIWizard) {
                AIWizardView()
            }
        }
        .navigationTitle("Home")
        .onAppear {
            workoutManager.loadCompletedWorkouts()
            viewModel.loadDashboard()
            viewModel.checkForPrograms()
            viewModel.computeWeeklyStats(from: workoutManager.completedWorkouts)

            if !didCheckForActiveWorkout {
                workoutManager.checkForActiveWorkout()
                didCheckForActiveWorkout = true
            }
        }
        .onChange(of: showCreateProgram) { oldValue, newValue in
            if oldValue && !newValue {
                viewModel.checkForPrograms()
            }
        }
        .onChange(of: showAIWizard) { oldValue, newValue in
            if oldValue && !newValue {
                viewModel.checkForPrograms()
            }
        }
        .onChange(of: workoutManager.completedWorkouts.count) {
            viewModel.computeWeeklyStats(from: workoutManager.completedWorkouts)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutDataUpdated"))) { _ in
            guard startedFromHero else { return }
            startedFromHero = false
            Task { @MainActor in
                await viewModel.advanceAfterCompletion()
            }
        }
    }

    // MARK: - Template → Workout

    private func startWorkoutFromTemplate(_ template: Template) {
        let exercises = template.exercises
            .sorted(by: { $0.orderIndex < $1.orderIndex })
            .map { templateExercise in
                let libraryItem = templateExercise.exerciseLibraryItem
                let exerciseName = libraryItem?.name ?? "Exercise"
                let muscles = libraryItem?.primaryMuscles ?? []
                let restSeconds = max(30, templateExercise.restSeconds ?? 90)
                let restMinutes = max(1, Int(round(Double(restSeconds) / 60.0)))

                return Exercise(
                    type: ExerciseType(name: exerciseName, muscleGroup: muscles),
                    exerciseServerId: libraryItem?.serverId,
                    example: libraryItem?.videoUrl?.absoluteString ?? "",
                    lastSetIntensityTechnique: templateExercise.notes ?? "Failure",
                    warmUpSets: templateExercise.warmupSets ?? 0,
                    workingSets: max(1, templateExercise.workingSets),
                    reps: parseRepsRange(from: templateExercise.targetReps),
                    rest: restMinutes...restMinutes
                )
            }

        let workoutName = template.name.isEmpty ? "Workout" : template.name
        let workout = Workout(name: workoutName, exercises: exercises)
        _ = workoutManager.startWorkout(template: workout)
    }

    private func parseRepsRange(from targetReps: String?) -> ClosedRange<Int> {
        guard let targetReps, !targetReps.isEmpty else { return 8...12 }
        let values = targetReps.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard let first = values.first else { return 8...12 }
        let lower = max(1, first)
        let upper = values.count > 1 ? max(lower, values[1]) : lower
        return lower...upper
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
                        startWorkoutFromHero()
                    }
                },
                onRotateBackward: program.workouts.count > 1 ? { viewModel.rotatePreviewBackward() } : nil,
                onRotateForward: program.workouts.count > 1 ? { viewModel.rotatePreviewForward() } : nil
            )
        } else {
            HeroWorkoutFallbackCard(onChooseProgram: {
                selectedTab = .programs
            })
        }
    }

    // MARK: - Start from Hero

    private func startWorkoutFromHero() {
        Task { @MainActor in
            await viewModel.commitPreviewBeforeStart()
            guard let template = viewModel.nextTemplate else {
                // Fallback to selection sheet if we couldn't resolve a template
                startNewWorkout = true
                return
            }
            let fallbackName = viewModel.nextWorkout?.displayName ?? template.name
            let workout = buildWorkout(from: template, fallbackName: fallbackName)
            startedFromHero = true
            _ = workoutManager.startWorkout(template: workout)
            showActiveWorkout = true
        }
    }

    private func buildWorkout(from template: Template, fallbackName: String) -> Workout {
        let exercises = template.exercises
            .sorted(by: { $0.orderIndex < $1.orderIndex })
            .map { templateExercise in
                let libraryItem = templateExercise.exerciseLibraryItem
                let exerciseName = libraryItem?.name ?? "Exercise"
                let muscles = libraryItem?.primaryMuscles ?? []
                let restSeconds = max(30, templateExercise.restSeconds ?? 90)
                let restMinutes = max(1, Int(round(Double(restSeconds) / 60.0)))

                return Exercise(
                    type: ExerciseType(name: exerciseName, muscleGroup: muscles),
                    exerciseServerId: libraryItem?.serverId,
                    example: libraryItem?.videoUrl?.absoluteString ?? "",
                    lastSetIntensityTechnique: templateExercise.notes ?? "Failure",
                    warmUpSets: templateExercise.warmupSets ?? 0,
                    workingSets: max(1, templateExercise.workingSets),
                    reps: parseRepsRange(from: templateExercise.targetReps),
                    rest: restMinutes...restMinutes
                )
            }

        let workoutName = template.name.isEmpty ? fallbackName : template.name
        return Workout(name: workoutName, exercises: exercises)
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
        HomeView(selectedTab: .constant(.home))
    }
    .withDependencies(.preview)
}
