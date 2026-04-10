//
//  WorkoutSelectionView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/11/25.
//

import SwiftUI

struct WorkoutSelectionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @ObservedObject var workoutManager = WorkoutManager.shared
    @State private var selectedPreviewWorkout: ProgramWorkout?

    var onWorkoutSelected: (TrackedWorkout) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            List {
                if dashboardViewModel.isLoading && dashboardViewModel.activeProgram == nil {
                    Section("Active Program") {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else if let program = dashboardViewModel.activeProgram {
                    Section("From Active Program: \(program.name)") {
                        ForEach(program.workouts.sorted(by: { $0.dayNumber < $1.dayNumber })) { workout in
                            if let template = dashboardViewModel.templateFor(workout: workout) {
                                HStack {
                                    // Preview toggle
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if selectedPreviewWorkout?.id == workout.id {
                                                selectedPreviewWorkout = nil
                                            } else {
                                                selectedPreviewWorkout = workout
                                            }
                                        }
                                    } label: {
                                        Image(systemName: selectedPreviewWorkout?.id == workout.id ? "eye.fill" : "eye")
                                            .foregroundStyle(selectedPreviewWorkout?.id == workout.id ? Color.appTheme : .secondary)
                                            .frame(width: 32, height: 32)
                                    }
                                    .buttonStyle(.plain)

                                    // Start workout button
                                    Button {
                                        startWorkout(template: workoutTemplate(from: template, fallbackName: workout.displayName))
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(workout.displayName)
                                                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.appTheme)
                                                Text("\(template.exerciseCount) exercises")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "play.circle.fill")
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                                .aspectRatio(contentMode: .fit)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .disabled(template.exercises.isEmpty)
                                    .tint(Color.appTheme)
                                    .buttonStyle(.automatic)
                                }
                            }
                        }
                    }

                    // Exercise preview carousel for selected workout
                    if let previewWorkout = selectedPreviewWorkout,
                       let template = dashboardViewModel.templateFor(workout: previewWorkout),
                       !template.exercises.isEmpty {
                        Section("Preview: \(previewWorkout.displayName)") {
                            ExerciseVideoCarousel(template: template, title: nil)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                } else {
                    Section("Active Program") {
                        Text("No active program. Set one in the Programs tab to start workouts from your plan.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .onChange(of: dashboardViewModel.nextWorkout) { _, nextWorkout in
                // Default to previewing the next workout
                if selectedPreviewWorkout == nil {
                    selectedPreviewWorkout = nextWorkout
                }
            }
        }
        .navigationTitle("Start Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            dashboardViewModel.loadDashboard()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    private func startWorkout(template: Workout) {
        let trackedWorkout = workoutManager.startWorkout(template: template)
        onWorkoutSelected(trackedWorkout)
        dismiss()
    }

    private func workoutTemplate(from template: Template, fallbackName: String) -> Workout {
        let exercises = template.exercises
            .sorted(by: { $0.orderIndex < $1.orderIndex })
            .map { templateExercise in
                let libraryItem = templateExercise.exerciseLibraryItem
                let exerciseName = libraryItem?.name ?? "Exercise"
                let muscles = libraryItem?.primaryMuscles ?? []

                return Exercise(
                    type: ExerciseType(name: exerciseName, muscleGroup: muscles),
                    example: libraryItem?.videoUrl?.absoluteString ?? "",
                    lastSetIntensityTechnique: templateExercise.notes ?? "Failure",
                    warmUpSets: templateExercise.warmupSets ?? 0,
                    workingSets: max(1, templateExercise.workingSets),
                    reps: repsRange(from: templateExercise.targetReps),
                    rest: restRange(from: templateExercise.restSeconds)
                )
            }

        let workoutName = template.name.isEmpty ? fallbackName : template.name
        return Workout(name: workoutName, exercises: exercises)
    }

    private func repsRange(from targetReps: String?) -> ClosedRange<Int> {
        guard let targetReps, !targetReps.isEmpty else { return 8...12 }

        let values = targetReps
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }

        guard let first = values.first else { return 8...12 }
        let lower = max(1, first)
        let upper = values.count > 1 ? max(lower, values[1]) : lower
        return lower...upper
    }

    private func restRange(from restSeconds: Int?) -> ClosedRange<Int> {
        let seconds = max(30, restSeconds ?? 90)
        let minutes = max(1, Int(round(Double(seconds) / 60.0)))
        return minutes...minutes
    }
}

#Preview {
    WorkoutSelectionView(onWorkoutSelected: { _ in })
}
