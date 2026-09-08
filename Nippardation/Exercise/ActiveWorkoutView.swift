//
//  ActiveWorkoutView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/14/25.
//
//  Active workout logger: hull screen, a stats panel (radius 14 + hairline), the exercises as a
//  list panel with eyebrow-sm labels over stepper numbers and a plasma check once sets exist,
//  and "End workout" as the destructive panel button behind a confirmation alert.
//

import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ActiveWorkoutViewModel
    
    // UI state properties
    @State private var selectedExercise: IdentifiableIndex?
    @State private var selectedDetent: PresentationDetent
    @State private var swappingExerciseIndex: Int?
    
    init(workout: TrackedWorkout) {
        // Initialize the view model with the workout
        _viewModel = StateObject(wrappedValue: ActiveWorkoutViewModel(workout: workout))
        selectedDetent = .large
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: VoidSpace.s3) {
                statsPanel
                exercisesSection
                endSection
            }
            .padding(.top, VoidSpace.s2)
            .padding(.bottom, VoidSpace.s6)
        }
        .voidScreen()
        .sheet(item: $selectedExercise) { identifiableIndex in
            ActiveExerciseDetailView(
                workout: $viewModel.workout,
                showingExerciseDetail: Binding(
                    get: { self.selectedExercise != nil },
                    set: { _ in self.selectedExercise = nil }
                ),
                exerciseIndex: identifiableIndex.value
            )
            .presentationDetents([.height(350), .height(180), .large], selection: $selectedDetent)
            .voidSheet()
            .interactiveDismissDisabled()
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
        .sheet(item: Binding(
            get: { swappingExerciseIndex.map { IdentifiableIndex(id: $0) } },
            set: { swappingExerciseIndex = $0?.value }
        )) { identifiableIndex in
            NavigationStack {
                ExerciseBrowserView { selected in
                    viewModel.swapExercise(at: identifiableIndex.value, to: selected)
                    swappingExerciseIndex = nil
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            swappingExerciseIndex = nil
                        }
                    }
                }
            }
            .tint(VoidColor.plasma)
        }
        .navigationTitle(viewModel.workout.workoutTemplate)
        .navigationBarTitleDisplayMode(.inline)
        .alert("End workout", isPresented: $viewModel.isShowingEndWorkoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("End workout", role: .destructive) {
                viewModel.endWorkout()
                dismiss()
            }
        } message: {
            Text("Your progress will be saved.")
        }
        .onAppear {
            viewModel.startTimer()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }
    
    // MARK: - Stats
    
    /// Duration / started, then completed sets / volume once a set is logged.
    private var statsPanel: some View {
        VStack(spacing: 14) {
            // Duration and start time row
            HStack(alignment: .top) {
                stat("Duration", viewModel.formattedElapsedTime)
                Spacer()
                stat("Started", startedText, alignment: .trailing)
            }
            
            // Completed sets and volume
            if viewModel.completedSets > 0 {
                VoidHairline()
                
                HStack(alignment: .top) {
                    stat("Completed sets", VoidFormat.pad2(viewModel.completedSets))
                    Spacer()
                    Button {
                        viewModel.cycleVolumeUnit()
                    } label: {
                        stat("Volume", viewModel.formattedTotalVolume, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(VoidPlainButtonStyle())
                    .accessibilityHint("Cycles the volume unit")
                }
            }
        }
        .padding(14)
        .voidPanel(radius: VoidRadius.panel, line: VoidColor.hairline)
        .padding(.horizontal, VoidSpace.insetCard)
    }
    
    private var startedText: String {
        viewModel.workout.startTime?.formatted(date: .omitted, time: .shortened) ?? "–"
    }
    
    private func stat(_ label: String, _ value: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label).voidEyebrowSm()
            Text(value)
                .font(VoidFont.stepper)
                .foregroundStyle(VoidColor.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Exercises
    
    private var exercises: [TrackedExercise] {
        viewModel.workout.trackedExercises
    }
    
    /// Eyebrow over a list panel of exercise rows. Long-press a row for Swap (the detail sheet
    /// also carries a "Swap movement" pill).
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s3) {
            VoidSectionRow(title: "Exercises")
            
            VoidListPanel {
                ForEach(Array(zip(exercises.indices, exercises)), id: \.0) { index, exercise in
                    Button {
                        selectedDetent = .large
                        selectedExercise = IdentifiableIndex(id: index)
                    } label: {
                        exerciseRow(exercise)
                    }
                    .buttonStyle(VoidRowButtonStyle())
                    .contextMenu {
                        Button {
                            swappingExerciseIndex = index
                        } label: {
                            Label("Swap", systemImage: VoidIcon.swap.systemName)
                        }
                    }
                    
                    if index < exercises.count - 1 {
                        VoidHairline()
                    }
                }
            }
        }
        .padding(.top, VoidSpace.s2)
    }
    
    private func exerciseRow(_ exercise: TrackedExercise) -> some View {
        HStack(spacing: VoidSpace.s3) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(VoidFont.bodyStrong)
                    .foregroundStyle(VoidColor.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text(setCaption(exercise))
                    .voidEyebrowSm(exercise.trackedSets.isEmpty ? VoidColor.text3 : VoidColor.text2)
                    .lineLimit(1)
            }
            
            Spacer(minLength: VoidSpace.s2)
            
            if !exercise.trackedSets.isEmpty {
                Image(systemName: VoidIcon.check.systemName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(VoidColor.plasma)
                    .accessibilityLabel("Logged")
            }
            
            VoidChevron()
        }
        .padding(.vertical, VoidSpace.s3)
        .frame(minHeight: VoidSize.listRow)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
    
    private func setCaption(_ exercise: TrackedExercise) -> String {
        let sets = exercise.trackedSets
        guard !sets.isEmpty else { return "No sets" }
        let volume = sets.reduce(0.0) { $0 + (Double($1.reps) * $1.weight) }
        let setWord = sets.count == 1 ? "set" : "sets"
        return VoidFormat.readout(["\(VoidFormat.pad2(sets.count)) \(setWord)", "\(Int(volume)) lbs"])
    }
    
    // MARK: - End workout
    
    /// Opens the confirmation alert; its destructive action ends the workout and closes the cover.
    private var endSection: some View {
        VoidDestructiveButton(title: "End workout") {
            viewModel.isShowingEndWorkoutAlert = true
        }
        .padding(.horizontal, VoidSpace.insetCard)
        .padding(.top, VoidSpace.s3)
    }
}

#Preview {
    NavigationStack {
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
}
