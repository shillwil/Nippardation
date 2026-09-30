//
//  ActiveExerciseDetailView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/14/25.
//
//  Exercise logging sheet: a native grouped list — the exercise name and position, the target,
//  the example video (AVKit's VideoPlayer), the logged sets and their totals, Swap movement —
//  with the system close button up top and two native buttons along the bottom: Add set and
//  Complete exercise. Complete marks the exercise done and hands off to the presenter, which
//  opens the next unfinished exercise. `isReadOnly` hides every editing control (previews).
//

import SwiftUI

struct ActiveExerciseDetailView: View {
    @StateObject private var viewModel: ActiveExerciseViewModel
    @ObservedObject var workoutManager = WorkoutManager.shared

    @Binding var workout: TrackedWorkout
    @Binding var showingExerciseDetail: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var isShowingAddSet = false
    @State private var isEditingSet = false
    @State private var selectedSetIndex: Int?
    @State private var editingReps: Int = 0
    @State private var editingWeight: Double = 0.0
    @State private var editingSetType: SetType = .working
    @State private var volumeUnit: VolumeUnit = .pounds
    @State private var isShowingSwapPicker = false
    @State private var isShowingSetsSavedNotice = false

    /// The first close ever explains that closing loses nothing: sets save as they're logged.
    @AppStorage("exerciseSheet.hasSeenSetsSavedNotice") private var hasSeenSetsSavedNotice = false

    let exerciseIndex: Int
    let isReadOnly: Bool
    /// Complete exercise hands the finished index here so the presenter can open the next
    /// exercise. Without one, completing just closes the sheet.
    let onComplete: ((Int) -> Void)?

    init(
        workout: Binding<TrackedWorkout>,
        showingExerciseDetail: Binding<Bool>,
        exerciseIndex: Int,
        isReadOnly: Bool = false,
        onComplete: ((Int) -> Void)? = nil
    ) {
        self._workout = workout
        self._showingExerciseDetail = showingExerciseDetail
        self.exerciseIndex = exerciseIndex
        self.isReadOnly = isReadOnly
        self.onComplete = onComplete

        // Create the view model with binding
        _viewModel = StateObject(wrappedValue: ActiveExerciseViewModel(
            workout: workout.wrappedValue,
            exerciseIndex: exerciseIndex
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if isReadOnly {
                    exerciseList
                } else {
                    exerciseList
                        .modifier(BottomActionBar { ctaBar })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SheetCloseButton(accessibilityLabel: isReadOnly ? "Close" : "Back to workout") {
                        closeTapped()
                    }
                }
            }
        }
        .alert("Your sets are saved", isPresented: $isShowingSetsSavedNotice) {
            Button("Got it") {
                close()
            }
        } message: {
            Text("Every set is saved the moment you log it, so closing never loses anything. Come back to this exercise anytime from your workout.")
        }
        .sheet(isPresented: $isShowingAddSet) {
            if let exercise = viewModel.matchingExercise {
                AddRepCountView(exercise: exercise) { newSet in
                    viewModel.addSet(newSet)
                    syncWorkoutBinding()
                }
                .presentationDetents([.fraction(0.75), .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $isEditingSet) {
            if let index = selectedSetIndex {
                EditSetView(
                    reps: $editingReps,
                    weight: $editingWeight,
                    setType: $editingSetType,
                    onSave: { newReps, newWeight, newSetType in
                        viewModel.updateSet(at: index, reps: newReps, weight: newWeight, setType: newSetType)
                        syncWorkoutBinding()
                    }
                )
                .presentationDetents([.fraction(0.75), .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $isShowingSwapPicker) {
            NavigationStack {
                ExerciseBrowserView { selected in
                    viewModel.swapExercise(to: selected)
                    syncWorkoutBinding()
                    isShowingSwapPicker = false
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
                            isShowingSwapPicker = false
                        }
                    }
                }
            }
            .tint(VoidColor.plasmaInk)
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Synchronize view model with the latest workout data
            viewModel.updateWorkout(workout)
        }
        .onChange(of: viewModel.workout) { _, newValue in
            // Keep the binding in sync with view model changes
            workout = newValue
        }
    }

    // MARK: - List

    private var exerciseList: some View {
        List {
            titleSection

            // Exercise information
            if let exercise = viewModel.matchingExercise {
                targetSection(exercise)
                videoSection(exercise)
            } else if isReadOnly {
                // Fallback for read-only mode when no matching exercise found
                Section {
                    Text("Exercise details not available")
                        .foregroundStyle(VoidColor.text2)
                }
            }

            // Logged sets (only when not read-only)
            if !isReadOnly {
                if viewModel.matchingExercise != nil {
                    setsSection

                    if viewModel.totalVolume > 0 {
                        totalsSection
                    }
                }

                Section {
                    Button("Swap movement", systemImage: VoidIcon.swap.systemName) {
                        isShowingSwapPicker = true
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Title

    private var titleSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text(positionReadout).voidEyebrowSm()

                if let currentExercise = viewModel.currentExercise {
                    Text(currentExercise.exerciseName)
                        .font(VoidFont.title)
                        .foregroundStyle(VoidColor.text)

                    if currentExercise.isCompleted {
                        Label {
                            Text("Completed")
                                .foregroundStyle(VoidColor.text2)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(VoidColor.plasma)
                        }
                        .font(VoidFont.caption)
                    }
                } else {
                    Text("No exercise available")
                        .font(VoidFont.title)
                        .foregroundStyle(VoidColor.text2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .listRowBackground(Color.clear)
        }
    }

    private var positionReadout: String {
        let total = viewModel.workout.trackedExercises.count
        guard total > 0 else { return "Exercise" }
        return "Exercise \(VoidFormat.ratio(viewModel.exerciseIndex + 1, total))"
    }

    // MARK: - Target info

    private func targetSection(_ exercise: Exercise) -> some View {
        Section("Target") {
            LabeledContent("Sets", value: "\(exercise.warmUpSets) warm-up + \(exercise.workingSets) working")
            LabeledContent("Reps", value: rangeText(exercise.reps))
            LabeledContent("Rest", value: "\(rangeText(exercise.rest)) min")
            LabeledContent("Intensity", value: exercise.lastSetIntensityTechnique)
        }
    }

    /// "8–12", or just "5" when both ends match.
    private func rangeText(_ range: ClosedRange<Int>) -> String {
        range.lowerBound == range.upperBound ? "\(range.lowerBound)" : "\(range.lowerBound)–\(range.upperBound)"
    }

    // MARK: - Video (native player from the backend URL, else the embedded example)

    @ViewBuilder
    private func videoSection(_ exercise: Exercise) -> some View {
        if let videoUrl = viewModel.nativeVideoUrl, let serverId = viewModel.exerciseServerId {
            Section("Example") {
                NativeVideoPlayer(exerciseServerId: serverId, videoUrl: videoUrl)
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        } else if viewModel.isResolvingVideo {
            // Holds the video's place while its current URL is fetched.
            Section("Example") {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .accessibilityLabel("Loading video")
            }
        } else if YouTubeEmbedView.isEmbed(exercise.example) {
            // Legacy templates store a YouTube <iframe>; plan workouts store the MP4 URL, which
            // plays in the native player above once it resolves.
            Section("Example") {
                YouTubeEmbedView(html: exercise.example)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
    }

    // MARK: - Sets

    private var trackedSets: [TrackedSet] {
        viewModel.currentExercise?.trackedSets ?? []
    }

    /// Tap a set to edit it; swipe or long-press for Edit and Delete.
    private var setsSection: some View {
        Section {
            if trackedSets.isEmpty {
                Text("No sets yet")
                    .foregroundStyle(VoidColor.text3)
            } else {
                ForEach(Array(trackedSets.enumerated()), id: \.element.id) { index, set in
                    Button {
                        startEditing(index: index, set: set)
                    } label: {
                        setRow(index: index, set: set)
                    }
                    // Explicit tints: swipe actions otherwise take the plasma tint (even the
                    // destructive one), and their white labels fail contrast on it.
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteSet(at: index)
                        } label: {
                            Label("Delete", systemImage: VoidIcon.trash.systemName)
                        }
                        .tint(.red)

                        Button {
                            startEditing(index: index, set: set)
                        } label: {
                            Label("Edit", systemImage: VoidIcon.edit.systemName)
                        }
                        .tint(.gray)
                    }
                    .contextMenu {
                        Button {
                            startEditing(index: index, set: set)
                        } label: {
                            Label("Edit", systemImage: VoidIcon.edit.systemName)
                        }

                        Button(role: .destructive) {
                            viewModel.deleteSet(at: index)
                        } label: {
                            Label("Delete", systemImage: VoidIcon.trash.systemName)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("Sets")
                Spacer()
                Text(VoidFormat.pad2(trackedSets.count))
            }
        }
    }

    private func setRow(index: Int, set: TrackedSet) -> some View {
        HStack(spacing: VoidSpace.s3) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Set \(VoidFormat.pad2(index + 1))")
                    .font(VoidFont.bodyStrong)
                    .foregroundStyle(VoidColor.text)
                Text(set.setType == .warmup ? "Warm-up" : "Working")
                    .voidEyebrowSm()
            }

            Spacer(minLength: VoidSpace.s2)

            HStack(spacing: VoidSpace.s3) {
                readout(VoidFormat.pad2(set.reps), unit: "reps")
                readout(weightText(set.weight), unit: "lbs")
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Edits this set")
    }

    private func readout(_ value: String, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(VoidFont.stepper)
                .foregroundStyle(VoidColor.text)
            Text(unit).voidEyebrowSm()
        }
    }

    /// "135", "46.25": whole pounds without a decimal, otherwise up to the two places a set keeps.
    private func weightText(_ weight: Double) -> String {
        weight.formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }

    private func startEditing(index: Int, set: TrackedSet) {
        selectedSetIndex = index
        editingReps = set.reps
        editingWeight = set.weight
        editingSetType = set.setType
        isEditingSet = true
    }

    // MARK: - Totals

    private var totalsSection: some View {
        Section("Totals") {
            LabeledContent("Sets", value: VoidFormat.pad2(trackedSets.count))
            LabeledContent("Reps", value: VoidFormat.pad2(viewModel.totalReps))
            LabeledContent("Volume") {
                Menu {
                    Picker("Volume unit", selection: $volumeUnit) {
                        ForEach(VolumeUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                } label: {
                    Text(formatVolume(viewModel.totalVolume))
                }
                .accessibilityHint("Chooses the volume unit")
            }
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        let convertedVolume = volumeUnit.convert(volume, from: .pounds)
        return volumeUnit.format(convertedVolume)
    }

    // MARK: - Bottom actions

    /// Add set and Complete exercise, side by side (stacked from xxLarge text up, where
    /// "Complete exercise" no longer fits half the width).
    /// Exactly one of them is prominent; see `ExerciseCTAState`.
    private var ctaBar: some View {
        let cta = viewModel.ctaState
        let layout = dynamicTypeSize >= .xxLarge
            ? AnyLayout(VStackLayout(spacing: VoidSpace.s2))
            : AnyLayout(HStackLayout(spacing: VoidSpace.s3))

        return layout {
            Button {
                isShowingAddSet = true
            } label: {
                CTALabel(title: "Add set", isProminent: cta.addSetIsPrimary)
            }
            .ctaButtonStyle(isProminent: cta.addSetIsPrimary)
            .disabled(!cta.canAddSet)

            Button(action: completeExercise) {
                CTALabel(title: "Complete exercise", isProminent: cta.completeIsPrimary)
            }
            .ctaButtonStyle(isProminent: cta.completeIsPrimary)
            .disabled(!cta.canComplete)
            .accessibilityHint(completeHint)
        }
        .controlSize(.large)
        .padding(.horizontal, VoidSpace.insetCard)
        .padding(.vertical, VoidSpace.s3)
    }

    private var completeHint: String {
        if onComplete != nil, let next = viewModel.nextExercise {
            return "Saves this exercise and opens \(next.exerciseName)"
        }
        return "Saves this exercise and returns to your workout"
    }

    // MARK: - Actions

    private func completeExercise() {
        viewModel.markComplete()
        persistCurrentExercise()
        if let onComplete {
            onComplete(viewModel.exerciseIndex)
        } else {
            showingExerciseDetail = false
        }
    }

    /// The first close ever shows the "sets are saved" note; after that it just closes.
    private func closeTapped() {
        if isReadOnly || hasSeenSetsSavedNotice {
            close()
        } else {
            hasSeenSetsSavedNotice = true
            isShowingSetsSavedNotice = true
        }
    }

    private func close() {
        if !isReadOnly {
            persistCurrentExercise()
        }
        showingExerciseDetail = false
    }

    /// Mirrors the view model's copy of this exercise into the workout binding.
    private func syncWorkoutBinding() {
        guard let currentExercise = viewModel.currentExercise,
              exerciseIndex >= 0 && exerciseIndex < workout.trackedExercises.count else { return }
        workout.trackedExercises[exerciseIndex] = currentExercise
    }

    /// Writes this exercise through the binding and WorkoutManager (sets are already saved as
    /// they're logged; this keeps the workout's copy identical to the sheet's).
    private func persistCurrentExercise() {
        guard let currentExercise = viewModel.currentExercise,
              exerciseIndex >= 0 && exerciseIndex < workout.trackedExercises.count else { return }
        workout.trackedExercises[exerciseIndex] = currentExercise
        workoutManager.updateExercise(at: exerciseIndex, with: currentExercise)
    }
}

// MARK: - Bottom bar chrome

/// Hosts the bottom buttons: iOS 26's safe-area bar (scroll-edge effect under glass buttons),
/// else a safe-area inset on the system bar material.
private struct BottomActionBar<Bar: View>: ViewModifier {
    @ViewBuilder let bar: () -> Bar

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: .bottom) { bar() }
        } else {
            content.safeAreaInset(edge: .bottom) {
                bar().background(.bar)
            }
        }
    }
}

/// A bottom-button label that keeps contrast: dark on the plasma fill, neutral otherwise,
/// and the system's dimmed colour while disabled.
private struct CTALabel: View {
    let title: String
    let isProminent: Bool

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Text(title)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .foregroundStyle(isEnabled ? (isProminent ? VoidColor.onPlasma : VoidColor.text) : Color.secondary)
    }
}

private extension View {
    /// Glass buttons over the scrolling list on iOS 26; bordered before it. Plasma only on
    /// the prominent one.
    @ViewBuilder
    func ctaButtonStyle(isProminent: Bool) -> some View {
        if #available(iOS 26.0, *) {
            if isProminent {
                self.buttonStyle(.glassProminent).tint(VoidColor.plasma)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            if isProminent {
                self.buttonStyle(.borderedProminent).tint(VoidColor.plasma)
            } else {
                self.buttonStyle(.bordered).tint(VoidColor.text)
            }
        }
    }
}

#Preview {
    ActiveExerciseDetailView(
        workout: .constant(TrackedWorkout(
            date: Date(),
            workoutTemplate: "Pull Day (Hypertrophy Focus)",
            trackedExercises: [
                TrackedExercise(
                    exerciseName: "Test Exercise",
                    muscleGroups: [MuscleGroup.shoulders.rawValue],
                    trackedSets: [
                        TrackedSet(reps: 8, weight: 32.5, setType: .warmup, exerciseType: ExerciseType(name: "EZ Bar Curl", muscleGroup: [.biceps]))
                    ]
                )
            ])
        ),
        showingExerciseDetail: .constant(true),
        exerciseIndex: 0)
}
