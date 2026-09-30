//
//  ExerciseConfigSheet.swift
//  Nippardation
//
//  Sets / reps / rest / notes for one exercise in the workout editor.
//  A system Form: stepper rows (hold to repeat), a notes field that grows, rest presets
//  as button toggles under the rest stepper, and a destructive Remove row.
//

import SwiftUI

struct ExerciseConfigSheet: View {

    let exercise: TemplateEditorViewModel.EditableExercise
    let onSave: (Int, Int, String, Int, String) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var warmupSets: Int
    @State private var workingSets: Int
    @State private var targetReps: String
    @State private var restSeconds: Int
    @State private var notes: String

    private let restOptions = [60, 90, 120, 180]

    init(
        exercise: TemplateEditorViewModel.EditableExercise,
        onSave: @escaping (Int, Int, String, Int, String) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.exercise = exercise
        self.onSave = onSave
        self.onDelete = onDelete
        self._warmupSets = State(initialValue: exercise.warmupSets)
        self._workingSets = State(initialValue: exercise.workingSets)
        self._targetReps = State(initialValue: exercise.targetReps)
        self._restSeconds = State(initialValue: exercise.restSeconds)
        self._notes = State(initialValue: exercise.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    header
                        .listRowBackground(Color.clear)
                }

                Section("Sets") {
                    Stepper(value: $warmupSets, in: 0...5) {
                        LabeledContent("Warmup sets", value: String(warmupSets))
                    }
                    Stepper(value: $workingSets, in: 1...10) {
                        LabeledContent("Working sets", value: String(workingSets))
                    }
                }

                Section {
                    LabeledContent("Target reps") {
                        TextField("8-12", text: $targetReps)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                    }
                    Stepper(value: $restSeconds, in: 0...600, step: 15) {
                        LabeledContent("Rest", value: ExerciseConfigFormat.rest(restSeconds))
                    }
                } header: {
                    Text("Reps and rest")
                } footer: {
                    restPresets
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Remove exercise", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .tint(VoidColor.plasmaInk)
            .navigationTitle("Configure exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(warmupSets, workingSets, targetReps, restSeconds, notes)
                        dismiss()
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s1) {
            Text(exercise.displayName)
                .font(VoidFont.title)
                .foregroundStyle(VoidColor.text)
                .lineLimit(2)

            if let muscles = exercise.exerciseLibraryItem?.primaryMuscles, !muscles.isEmpty {
                Text(muscles.map { $0.rawValue.capitalized }.joined(separator: VoidFormat.dot))
                    .font(VoidFont.caption)
                    .foregroundStyle(VoidColor.text2)
            }
        }
    }

    /// One-tap rest values for the stepper above. They live in the section footer rather
    /// than a row, so each toggle stays its own tap target instead of joining the row's.
    private var restPresets: some View {
        HStack(spacing: VoidSpace.s2) {
            ForEach(restOptions, id: \.self) { seconds in
                ChipToggle(
                    title: ExerciseConfigFormat.rest(seconds),
                    isOn: restSeconds == seconds
                ) { isOn in
                    // Picking a preset sets the rest; tapping the current one keeps it.
                    if isOn {
                        restSeconds = seconds
                    }
                }
                .accessibilityLabel("Rest \(ExerciseConfigFormat.rest(seconds))")
            }
        }
        .padding(.top, VoidSpace.s1)
    }
}

// MARK: - Previews

#Preview {
    ExerciseConfigSheet(
        exercise: TemplateEditorViewModel.EditableExercise(
            orderIndex: 0,
            exerciseServerId: "ex_001",
            exerciseLibraryItem: MockExerciseRepository.sampleExercises[0],
            warmupSets: 2,
            workingSets: 4,
            targetReps: "6-8",
            restSeconds: 180,
            notes: ""
        ),
        onSave: { _, _, _, _, _ in },
        onDelete: {}
    )
}
