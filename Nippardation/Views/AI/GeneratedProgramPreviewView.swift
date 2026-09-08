//
//  GeneratedProgramPreviewView.swift
//  Nippardation
//
//  Review an AI-generated plan before saving: rename it, remove exercises, then Save or Discard.
//

import SwiftUI

struct GeneratedProgramPreviewView: View {
    @StateObject private var viewModel: GeneratedProgramPreviewViewModel
    @Environment(\.dismiss) private var dismiss

    let onSave: () -> Void
    let onDiscard: () -> Void

    init(
        program: Program,
        metadata: GenerationMetadataDTO?,
        reusedTemplateIds: Set<String> = [],
        onSave: @escaping () -> Void,
        onDiscard: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: GeneratedProgramPreviewViewModel(
            program: program,
            metadata: metadata,
            reusedTemplateIds: reusedTemplateIds
        ))
        self.onSave = onSave
        self.onDiscard = onDiscard
    }

    var body: some View {
        List {
            Section {
                headerPanel
                planFields
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: VoidSpace.insetCard, bottom: 6, trailing: VoidSpace.insetCard))
            .listSectionSeparator(.hidden)

            ForEach(Array(viewModel.workouts.enumerated()), id: \.element.id) { workoutIndex, workout in
                Section {
                    rotationRow(workout, index: workoutIndex)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 14, leading: VoidSpace.insetText, bottom: 6, trailing: VoidSpace.insetText))

                    ForEach(workout.exercises) { exercise in
                        EditableExerciseRow(
                            exercise: exerciseBinding(workoutIndex: workoutIndex, id: exercise.id, fallback: exercise),
                            onDelete: { remove(workoutIndex: workoutIndex, id: exercise.id) }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(VoidColor.hairline)
                        .listRowInsets(EdgeInsets(top: 12, leading: VoidSpace.insetText, bottom: 12, trailing: VoidSpace.insetText))
                    }
                    .onDelete { offsets in
                        for index in offsets.sorted(by: >) {
                            viewModel.removeExercise(workoutIndex: workoutIndex, exerciseIndex: index)
                        }
                    }
                }
                .listSectionSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.interactively)
        .voidScreen()
        .navigationTitle("Review plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    onDiscard()
                } label: {
                    Text("Discard")
                        .font(VoidFont.body)
                        .foregroundStyle(VoidColor.warning)
                }
                .disabled(viewModel.isSaving)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.save()
                } label: {
                    Text("Save")
                        .font(VoidFont.button)
                        .foregroundStyle(VoidColor.plasma)
                }
                .disabled(viewModel.isSaving)
            }
        }
        .overlay {
            if viewModel.isSaving {
                WizardBusyOverlay(eyebrow: "Saving")
            }
        }
        .onChange(of: viewModel.savedSuccessfully) { _, saved in
            if saved {
                onSave()
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: - Header

    private var headerTitle: String {
        if let ms = viewModel.metadata?.timeMs {
            let seconds = Int((Double(ms) / 1000).rounded())
            return "AI plan · generated in \(VoidFormat.pad2(seconds)) s"
        }
        return "AI plan"
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            AISectionHeader(headerTitle)

            Text(VoidFormat.readout([
                "\(viewModel.originalProgram.daysPerWeek) DAYS / WK",
                VoidFormat.exercises(viewModel.totalExercises),
                viewModel.originalProgram.durationWeeks.map { VoidFormat.weeks($0) }
            ]))
            .voidReadout()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(VoidSpace.s4)
        .voidPanel(radius: VoidRadius.panel, line: VoidColor.hairline)
    }

    private var planFields: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s2) {
            WizardSectionLabel(title: "Plan")
            VoidTextField(placeholder: "Plan name", text: $viewModel.programName, icon: .edit)
            WizardTextArea(placeholder: "Description, optional", text: $viewModel.programDescription, lines: 2...4)
        }
        .padding(.top, VoidSpace.s2)
    }

    // MARK: - Rotation row

    private func rotationRow(_ workout: GeneratedProgramPreviewViewModel.EditableWorkout, index: Int) -> some View {
        // The AI mapper gives every workout an empty serverId, so match the original by rotation order.
        let originals = viewModel.originalProgram.workouts.sorted { $0.dayNumber < $1.dayNumber }
        let templateServerId = index < originals.count ? originals[index].templateServerId : nil

        let badge: (text: String, color: Color)?
        if !viewModel.reusedTemplateIds.isEmpty, let templateServerId {
            if viewModel.reusedTemplateIds.contains(templateServerId) {
                badge = (text: "Reused", color: VoidColor.plasma)
            } else {
                badge = (text: "New", color: VoidColor.text2)
            }
        } else {
            badge = nil
        }

        return HStack(spacing: 14) {
            WorkoutTile(glyph: VoidIcon.workoutGlyph(for: workout.dayLabel))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    Text(VoidFormat.readout([
                        "DAY \(VoidFormat.pad2(index + 1))",
                        VoidFormat.exercises(workout.exercises.count)
                    ]))
                    .voidEyebrowSm()

                    if let badge {
                        Text(VoidFormat.dot).voidEyebrowSm()
                        Text(badge.text).voidEyebrowSm(badge.color)
                    }
                }

                Text(workout.dayLabel)
                    .voidWordRow()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Bindings

    private func exerciseBinding(
        workoutIndex: Int,
        id: UUID,
        fallback: GeneratedProgramPreviewViewModel.EditableExercise
    ) -> Binding<GeneratedProgramPreviewViewModel.EditableExercise> {
        Binding(
            get: {
                guard viewModel.workouts.indices.contains(workoutIndex) else { return fallback }
                return viewModel.workouts[workoutIndex].exercises.first { $0.id == id } ?? fallback
            },
            set: { updated in
                guard viewModel.workouts.indices.contains(workoutIndex),
                      let exerciseIndex = viewModel.workouts[workoutIndex].exercises.firstIndex(where: { $0.id == id })
                else { return }
                viewModel.workouts[workoutIndex].exercises[exerciseIndex] = updated
            }
        )
    }

    private func remove(workoutIndex: Int, id: UUID) {
        guard viewModel.workouts.indices.contains(workoutIndex),
              let exerciseIndex = viewModel.workouts[workoutIndex].exercises.firstIndex(where: { $0.id == id })
        else { return }
        viewModel.removeExercise(workoutIndex: workoutIndex, exerciseIndex: exerciseIndex)
    }
}

// MARK: - Editable Exercise Row

struct EditableExerciseRow: View {
    @Binding var exercise: GeneratedProgramPreviewViewModel.EditableExercise
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: VoidSpace.s2) {
            VStack(alignment: .leading, spacing: VoidSpace.s2) {
                Text(exercise.name)
                    .font(VoidFont.bodyStrong)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(2)

                HStack(spacing: VoidSpace.s2) {
                    field("Sets") {
                        WizardIntField(placeholder: "0", value: $exercise.workingSets, height: 36)
                    }
                    field("Reps") {
                        repsWell
                    }
                    field("Rest s") {
                        WizardIntField(placeholder: "0", value: $exercise.restSeconds, height: 36)
                    }
                }
            }

            Spacer(minLength: 0)

            Button(action: onDelete) {
                Image(systemName: VoidIcon.close.systemName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(VoidColor.text2)
                    .frame(width: VoidSize.hitMin, height: VoidSize.hitMin)
            }
            .buttonStyle(VoidPlainButtonStyle())
            .accessibilityLabel("Remove \(exercise.name)")
        }
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: VoidSpace.s1) {
            Text(label).voidEyebrowSm()
            content()
                .accessibilityLabel("\(exercise.name), \(label)")
        }
        .frame(width: 76)
    }

    private var repsWell: some View {
        TextField("8-12", text: $exercise.targetReps)
            .font(VoidFont.body)
            .foregroundStyle(VoidColor.text)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .frame(height: 36)
            .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2, fill: VoidColor.panel2)
    }
}

#Preview {
    let program = AIGeneratedProgramMapper.toDomain(MockAIAPIService.sampleGenerateResponse.program)
    NavigationStack {
        GeneratedProgramPreviewView(
            program: program,
            metadata: MockAIAPIService.sampleGenerateResponse.generation,
            reusedTemplateIds: ["ai_tmpl_001"],
            onSave: {},
            onDiscard: {}
        )
    }
    .withDependencies(.preview)
}
