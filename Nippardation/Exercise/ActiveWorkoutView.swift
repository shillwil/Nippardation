//
//  ActiveWorkoutView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/14/25.
//
//  Active workout logger: a native grouped list — the duration / start / totals readout, the
//  exercises (tap to log, swipe or long-press to swap, a plasma check once completed), and
//  End workout as a destructive row behind a confirmation alert. Completing an exercise moves
//  the open sheet on to the next unfinished exercise in place.
//

import SwiftUI

/// One presentation of the exercise sheet. Its id stays fixed while `index` moves from
/// exercise to exercise, so completing one swaps the sheet's content instead of dismissing
/// and presenting it again.
struct ExerciseSheetRoute: Identifiable, Equatable {
    let id = UUID()
    var index: Int
}

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel: ActiveWorkoutViewModel

    // UI state properties
    @State private var exerciseSheet: ExerciseSheetRoute?
    @State private var selectedDetent: PresentationDetent = .large
    @State private var swappingExerciseIndex: Int?
    /// Bumped by every Complete exercise, for the success haptic.
    @State private var completionCount = 0

    init(workout: TrackedWorkout) {
        // Initialize the view model with the workout
        _viewModel = StateObject(wrappedValue: ActiveWorkoutViewModel(workout: workout))
    }

    var body: some View {
        List {
            statsSection
            exercisesSection
            endSection
        }
        .listStyle(.insetGrouped)
        .voidScreen()
        .sheet(item: $exerciseSheet) { route in
            ActiveExerciseDetailView(
                workout: $viewModel.workout,
                showingExerciseDetail: Binding(
                    get: { exerciseSheet != nil },
                    set: { isShowing in
                        if !isShowing { exerciseSheet = nil }
                    }
                ),
                exerciseIndex: route.index,
                onComplete: advance(from:)
            )
            // A new index is a new exercise: fresh view model, video and scroll position,
            // while the sheet itself stays up.
            .id(route.index)
            .presentationDetents([.height(350), .height(180), .large], selection: $selectedDetent)
            .presentationDragIndicator(.visible)
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
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
                            swappingExerciseIndex = nil
                        }
                    }
                }
            }
            .tint(VoidColor.plasmaInk)
            .presentationDragIndicator(.visible)
        }
        .sensoryFeedback(.success, trigger: completionCount)
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
    }

    // MARK: - Stats

    /// Duration / started, then logged sets / volume once a set is logged.
    private var statsSection: some View {
        Section {
            VStack(spacing: 14) {
                // Duration and start time row
                HStack(alignment: .top) {
                    stat("Duration") { durationText }
                    Spacer()
                    stat("Started", alignment: .trailing) { Text(startedText) }
                }

                // Logged sets and volume
                if viewModel.completedSets > 0 {
                    Divider()

                    HStack(alignment: .top) {
                        stat("Sets logged") { Text(VoidFormat.pad2(viewModel.completedSets)) }
                        Spacer()
                        Menu {
                            Picker("Volume unit", selection: $viewModel.volumeUnit) {
                                ForEach(VolumeUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                        } label: {
                            stat("Volume", alignment: .trailing) { Text(viewModel.formattedTotalVolume) }
                        }
                        .accessibilityHint("Chooses the volume unit")
                    }
                }
            }
            .padding(.vertical, VoidSpace.s1)
            .listRowBackground(VoidColor.panel)
        }
    }

    /// Counts up from the start time on its own, so it never drifts while the list scrolls
    /// or the phone sleeps between sets.
    @ViewBuilder
    private var durationText: some View {
        if let startTime = viewModel.workout.startTime {
            Text(timerInterval: startTime...Date.distantFuture, countsDown: false)
        } else {
            Text("–")
        }
    }

    private var startedText: String {
        viewModel.workout.startTime?.formatted(date: .omitted, time: .shortened) ?? "–"
    }

    private func stat<Value: View>(
        _ label: String,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder value: () -> Value
    ) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label).voidEyebrowSm()
            value()
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

    /// Tap a row to log it; swipe or long-press it for Swap (the sheet also carries
    /// "Swap movement").
    private var exercisesSection: some View {
        Section("Exercises") {
            ForEach(Array(zip(exercises.indices, exercises)), id: \.1.id) { index, exercise in
                Button {
                    open(index)
                } label: {
                    exerciseRow(exercise)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        swappingExerciseIndex = index
                    } label: {
                        Label("Swap", systemImage: VoidIcon.swap.systemName)
                    }
                    // Explicit: an untinted action takes the plasma tint, and its white label
                    // fails contrast on it.
                    .tint(.gray)
                }
                .contextMenu {
                    Button {
                        swappingExerciseIndex = index
                    } label: {
                        Label("Swap", systemImage: VoidIcon.swap.systemName)
                    }
                }
                .listRowBackground(VoidColor.panel)
            }
        }
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
                    .voidEyebrowSm(exercise.hasLoggedSets ? VoidColor.text2 : VoidColor.text3)
                    .lineLimit(1)
            }

            Spacer(minLength: VoidSpace.s2)

            if exercise.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(VoidColor.plasma)
                    .accessibilityHidden(true) // the row's value already says "Completed"
            }
        }
        .padding(.vertical, VoidSpace.s1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(status(of: exercise))
    }

    private func status(of exercise: TrackedExercise) -> String {
        if exercise.isCompleted { return "Completed" }
        return exercise.hasLoggedSets ? "In progress" : "Not started"
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
        Section {
            Button("End workout", role: .destructive) {
                viewModel.isShowingEndWorkoutAlert = true
            }
            .listRowBackground(VoidColor.panel)
        }
    }

    // MARK: - Exercise sheet

    /// Opens an exercise, or switches the open sheet to it (rows stay tappable behind the
    /// sheet at its small detents).
    private func open(_ index: Int) {
        selectedDetent = .large
        if exerciseSheet != nil {
            exerciseSheet?.index = index
        } else {
            exerciseSheet = ExerciseSheetRoute(index: index)
        }
    }

    /// Complete exercise: move the sheet on to the next unfinished exercise, or close it
    /// back to this list when every exercise is done.
    private func advance(from index: Int) {
        completionCount += 1
        let finished = exercises.indices.contains(index) ? exercises[index].exerciseName : "Exercise"

        guard let next = viewModel.nextUnfinishedExercise(after: index) else {
            exerciseSheet = nil
            announce("\(finished) complete. That's every exercise.")
            return
        }

        selectedDetent = .large
        withAnimation(reduceMotion ? nil : .smooth) {
            exerciseSheet?.index = next
        }
        announce("\(finished) complete. Next: \(exercises[next].exerciseName).")
    }

    /// High priority, so the sheet's content swap (or dismissal) doesn't cut it off.
    private func announce(_ message: String) {
        var announcement = AttributedString(message)
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
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
