//
//  ActiveExerciseDetailView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/14/25.
//
//  Exercise detail sheet: panel chrome with a grabber, eyebrow position readout over the
//  exercise name, target panel, the embedded example video, the logged sets as a list panel,
//  and one plasma CTA (Add set). `isReadOnly` hides every editing control (used by previews).
//

import SwiftUI

struct ActiveExerciseDetailView: View {
    @StateObject private var viewModel: ActiveExerciseViewModel
    @ObservedObject var workoutManager = WorkoutManager.shared
    
    @Binding var workout: TrackedWorkout
    @Binding var showingExerciseDetail: Bool
    
    @State private var isShowingAddSet = false
    @State private var isEditingSet = false
    @State private var selectedSetIndex: Int?
    @State private var editingReps: Int = 0
    @State private var editingWeight: Double = 0.0
    @State private var editingSetType: SetType = .working
    @State private var showingCancelAlert = false
    @State private var volumeUnit: VolumeUnit = .pounds
    @State private var isShowingSwapPicker = false
    
    let exerciseIndex: Int
    let isReadOnly: Bool
    
    init(workout: Binding<TrackedWorkout>, showingExerciseDetail: Binding<Bool>, exerciseIndex: Int, isReadOnly: Bool = false) {
        self._workout = workout
        self._showingExerciseDetail = showingExerciseDetail
        self.exerciseIndex = exerciseIndex
        self.isReadOnly = isReadOnly
        
        // Create the view model with binding
        _viewModel = StateObject(wrappedValue: ActiveExerciseViewModel(
            workout: workout.wrappedValue,
            exerciseIndex: exerciseIndex
        ))
    }
    
    var body: some View {
        workoutView
            .environmentObject(viewModel)
    }
    
    private var workoutView: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                VStack(alignment: .leading, spacing: VoidSpace.s5) {
                    titleBlock
                    
                    // Exercise information
                    if let exercise = viewModel.matchingExercise {
                        targetPanel(exercise)
                        videoSection(exercise)
                    } else if isReadOnly {
                        // Fallback for read-only mode when no matching exercise found
                        Text("Exercise details not available")
                            .font(VoidFont.caption)
                            .foregroundStyle(VoidColor.text2)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, VoidSpace.s4)
                    }
                    
                    // Logged sets (only when not read-only)
                    if !isReadOnly {
                        if viewModel.matchingExercise != nil {
                            setsSection
                            
                            if viewModel.totalVolume > 0 {
                                summaryPanel
                            }
                        }
                        
                        swapMovementButton
                    }
                }
                .padding(.top, VoidSpace.s2)
                .padding(.bottom, VoidSpace.s6)
            }
            
            if !isReadOnly {
                ctaBar
            }
        }
        .background(VoidColor.panel.ignoresSafeArea())
        .alert("Cancel exercise", isPresented: $showingCancelAlert) {
            Button("Go back", role: .cancel) {
                // Just dismiss the alert
            }
            
            Button("Close anyway", role: .destructive) {
                showingExerciseDetail = false
            }
        } message: {
            Text("You have sets logged for this exercise. Close without finishing?")
        }
        .sheet(isPresented: $isShowingAddSet) {
            if let exercise = viewModel.matchingExercise {
                AddRepCountView(exercise: exercise) { newSet in
                    viewModel.addSet(newSet)
                    // Update the binding to ensure changes propagate (with bounds check)
                    if let currentExercise = viewModel.currentExercise,
                       exerciseIndex >= 0 && exerciseIndex < workout.trackedExercises.count {
                        workout.trackedExercises[exerciseIndex] = currentExercise
                    }
                }
                .presentationDetents([.fraction(0.75)])
                .voidSheet()
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
                        // Update the binding to ensure changes propagate (with bounds check)
                        if let currentExercise = viewModel.currentExercise,
                           exerciseIndex >= 0 && exerciseIndex < workout.trackedExercises.count {
                            workout.trackedExercises[exerciseIndex] = currentExercise
                        }
                    }
                )
                .presentationDetents([.height(430), .large])
                .voidSheet()
            }
        }
        .sheet(isPresented: $isShowingSwapPicker) {
            NavigationStack {
                ExerciseBrowserView { selected in
                    viewModel.swapExercise(to: selected)
                    if let currentExercise = viewModel.currentExercise,
                       exerciseIndex >= 0 && exerciseIndex < workout.trackedExercises.count {
                        workout.trackedExercises[exerciseIndex] = currentExercise
                    }
                    isShowingSwapPicker = false
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            isShowingSwapPicker = false
                        }
                    }
                }
            }
            .tint(VoidColor.plasma)
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
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 0) {
            VoidGrabber()
                .padding(.top, 10)
                .padding(.bottom, 14)
            
            HStack {
                if isReadOnly {
                    textButton("Close") {
                        showingExerciseDetail = false
                    }
                } else {
                    cancelButton
                }
                
                Spacer()
                
                if !isReadOnly {
                    textButton("Done") {
                        saveAndClose()
                    }
                }
            }
            // The text buttons carry 8pt of extra hit area each side; pull the row in so the labels stay on the 20pt line.
            .padding(.horizontal, VoidSpace.insetText - VoidSpace.s2)
            .padding(.bottom, VoidSpace.s2)
        }
    }
    
    /// SF 15 plasma text control: 44pt tall, hit area reaching 8pt past the label on each side.
    private func textButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(VoidFont.button)
                .foregroundStyle(VoidColor.plasma)
                .padding(.horizontal, VoidSpace.s2)
                .frame(minHeight: VoidSize.hitMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(VoidPlainButtonStyle())
    }
    
    private var cancelButton: some View {
        textButton("Cancel") {
            if let currentExercise = viewModel.currentExercise, !currentExercise.trackedSets.isEmpty {
                showingCancelAlert = true
            } else {
                showingExerciseDetail = false
            }
        }
    }
    
    // MARK: - Title
    
    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(positionReadout).voidEyebrowSm()
            
            if let currentExercise = viewModel.currentExercise {
                Text(currentExercise.exerciseName)
                    .font(VoidFont.title)
                    .foregroundStyle(VoidColor.text)
            } else {
                Text("No exercise available")
                    .font(VoidFont.title)
                    .foregroundStyle(VoidColor.text2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, VoidSpace.insetText)
    }
    
    private var positionReadout: String {
        let total = viewModel.workout.trackedExercises.count
        guard total > 0 else { return "Exercise" }
        return "Exercise \(VoidFormat.ratio(viewModel.exerciseIndex + 1, total))"
    }
    
    // MARK: - Target info
    
    private func targetPanel(_ exercise: Exercise) -> some View {
        VStack(spacing: 0) {
            targetRow("Target sets", "\(exercise.warmUpSets) warm-up + \(exercise.workingSets) working")
            VoidHairline()
            targetRow("Target reps", "\(exercise.reps.lowerBound)–\(exercise.reps.upperBound)")
            VoidHairline()
            targetRow("Rest", "\(exercise.rest.lowerBound)–\(exercise.rest.upperBound) min")
            VoidHairline()
            targetRow("Intensity", exercise.lastSetIntensityTechnique)
        }
        .padding(.horizontal, 14)
        .voidPanel(radius: VoidRadius.panel, line: .clear, fill: VoidColor.panel2)
        .padding(.horizontal, VoidSpace.insetCard)
    }
    
    private func targetRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).voidEyebrowSm()
            Spacer(minLength: VoidSpace.s3)
            Text(value)
                .font(VoidFont.body)
                .foregroundStyle(VoidColor.text)
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: VoidSize.hitMin)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Video (native player from the backend URL, else the embedded example)
    
    @ViewBuilder
    private func videoSection(_ exercise: Exercise) -> some View {
        if let videoUrl = viewModel.nativeVideoUrl, let serverId = viewModel.exerciseServerId {
            VStack(alignment: .leading, spacing: VoidSpace.s2) {
                Text("Example").voidEyebrowSm()
                    .padding(.horizontal, VoidSpace.insetText)
                
                NativeVideoPlayer(
                    exerciseServerId: serverId,
                    videoUrl: videoUrl,
                    showControls: true
                )
                .frame(maxHeight: 400)
                .padding(.horizontal, VoidSpace.insetCard)
            }
        } else if !exercise.example.isEmpty {
            VStack(alignment: .leading, spacing: VoidSpace.s2) {
                Text("Example").voidEyebrowSm()
                    .padding(.horizontal, VoidSpace.insetText)
                
                YouTubeEmbedView(html: exercise.example)
                    .aspectRatio(1.8, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
                    .frame(height: 200)
                    .padding(.horizontal, VoidSpace.insetCard)
            }
        }
    }
    
    // MARK: - Sets
    
    private var trackedSets: [TrackedSet] {
        viewModel.currentExercise?.trackedSets ?? []
    }
    
    private var setsSection: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s3) {
            VoidSectionRow(title: "Sets", trailing: VoidFormat.pad2(trackedSets.count))
            
            if trackedSets.isEmpty {
                Text("No sets yet")
                    .font(VoidFont.caption)
                    .foregroundStyle(VoidColor.text3)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, VoidSpace.s4)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(zip(trackedSets.indices, trackedSets)), id: \.0) { index, set in
                        setRow(index: index, set: set)
                        if index < trackedSets.count - 1 {
                            VoidHairline()
                        }
                    }
                }
                .padding(.horizontal, 14)
                .voidPanel(radius: VoidRadius.panel, line: .clear, fill: VoidColor.panel2)
                .padding(.horizontal, VoidSpace.insetCard)
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
            
            // Edit and Delete (only when not read-only)
            if !isReadOnly {
                Menu {
                    Button {
                        selectedSetIndex = index
                        editingReps = set.reps
                        editingWeight = set.weight
                        editingSetType = set.setType
                        isEditingSet = true
                    } label: {
                        Label("Edit", systemImage: VoidIcon.edit.systemName)
                    }
                    
                    Button(role: .destructive) {
                        viewModel.deleteSet(at: index)
                    } label: {
                        Label("Delete", systemImage: VoidIcon.trash.systemName)
                    }
                } label: {
                    Image(systemName: VoidIcon.more.systemName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(VoidColor.text2)
                        .frame(width: VoidSize.hitMin, height: VoidSize.hitMin)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Set \(index + 1) options")
            }
        }
        .frame(minHeight: VoidSize.listRow)
    }
    
    private func readout(_ value: String, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(VoidFont.stepper)
                .foregroundStyle(VoidColor.text)
            Text(unit).voidEyebrowSm()
        }
        .accessibilityElement(children: .combine)
    }
    
    private func weightText(_ weight: Double) -> String {
        weight.rounded() == weight ? "\(Int(weight))" : String(format: "%.1f", weight)
    }
    
    // MARK: - Summary
    
    private var summaryPanel: some View {
        HStack(alignment: .top) {
            summaryStat("Sets", VoidFormat.pad2(trackedSets.count))
            Spacer()
            summaryStat("Reps", VoidFormat.pad2(viewModel.totalReps))
            Spacer()
            Button {
                volumeUnit = volumeUnit.next()
            } label: {
                summaryStat("Volume", formatVolume(viewModel.totalVolume), alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(VoidPlainButtonStyle())
            .accessibilityHint("Cycles the volume unit")
        }
        .padding(14)
        .voidPanel(radius: VoidRadius.panel, line: .clear, fill: VoidColor.panel2)
        .padding(.horizontal, VoidSpace.insetCard)
    }
    
    private func summaryStat(_ label: String, _ value: String, alignment: HorizontalAlignment = .leading) -> some View {
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
    
    private func formatVolume(_ volume: Double) -> String {
        let convertedVolume = volumeUnit.convert(volume, from: .pounds)
        return volumeUnit.format(convertedVolume)
    }
    
    // MARK: - Actions
    
    private var swapMovementButton: some View {
        VoidPillButton(title: "Swap movement") {
            isShowingSwapPicker = true
        }
        .padding(.horizontal, VoidSpace.insetCard)
    }
    
    private var ctaBar: some View {
        VoidCTAButton(title: "Add set", isEnabled: viewModel.matchingExercise != nil) {
            isShowingAddSet = true
        }
        .padding(.horizontal, VoidSpace.insetCard)
        .padding(.top, VoidSpace.s3)
        .padding(.bottom, VoidSpace.s3)
        .background(VoidColor.panel)
    }
    
    private func saveAndClose() {
        // Save changes through the workout binding (with bounds check)
        if let currentExercise = viewModel.currentExercise,
           exerciseIndex >= 0 && exerciseIndex < workout.trackedExercises.count {
            workout.trackedExercises[exerciseIndex] = currentExercise
            // Update in workout manager
            workoutManager.updateExercise(at: exerciseIndex, with: currentExercise)
        }
        showingExerciseDetail = false
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
