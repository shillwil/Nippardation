//
//  ExerciseConfigSheet.swift
//  Nippardation
//
//  Sets / reps / rest / notes for one exercise in the workout editor.
//  Void sheet: panel background, panel-2 stepper wells (radius 12), stepper numbers.
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
            ScrollView {
                VStack(alignment: .leading, spacing: VoidSpace.s5) {
                    header

                    section("Sets") {
                        HStack(spacing: 10) {
                            ExerciseStepperWell(label: "Warmup", value: $warmupSets, range: 0...5)
                            ExerciseStepperWell(label: "Working", value: $workingSets, range: 1...10)
                        }
                    }

                    section("Reps and rest") {
                        HStack(spacing: 10) {
                            repsWell
                            ExerciseStepperWell(
                                label: "Rest",
                                value: $restSeconds,
                                range: 0...600,
                                step: 15,
                                display: ExerciseConfigFormat.rest
                            )
                        }
                        HStack(spacing: VoidSpace.s2) {
                            ForEach(restOptions, id: \.self) { seconds in
                                VoidSquareChip(
                                    text: ExerciseConfigFormat.rest(seconds),
                                    isSelected: restSeconds == seconds
                                ) {
                                    restSeconds = seconds
                                }
                            }
                        }
                    }

                    section("Notes") {
                        MultilineTextWell(placeholder: "Notes (optional)", text: $notes)
                    }

                    VoidDestructiveButton(title: "Remove exercise") {
                        onDelete()
                        dismiss()
                    }
                    .padding(.top, VoidSpace.s1)
                }
                .padding(.horizontal, VoidSpace.insetText)
                .padding(.top, VoidSpace.s3)
                .padding(.bottom, VoidSpace.s6)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(VoidColor.panel.ignoresSafeArea())
            .toolbarBackground(VoidColor.panel, for: .navigationBar)
            .tint(VoidColor.plasma)
            .navigationTitle("Configure exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(warmupSets, workingSets, targetReps, restSeconds, notes)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .voidSheet()
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

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: VoidSpace.s2) {
            Text(title)
                .voidEyebrowSm()
            content()
        }
    }

    /// Text well matching the stepper wells: "8-12" in the stepper font.
    private var repsWell: some View {
        VStack(spacing: VoidSpace.s2) {
            Text("Reps")
                .voidEyebrowSm()
            TextField("8-12", text: $targetReps)
                .font(VoidFont.stepper)
                .foregroundStyle(VoidColor.text)
                .multilineTextAlignment(.center)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
                .frame(height: VoidSize.hitMin)
                .accessibilityLabel("Target reps")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .background(VoidColor.panel2)
        .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
    }
}

// MARK: - Stepper well

/// Panel-2 well (radius 12): eyebrow label over [−] number [+]. Numbers in `VoidFont.stepper`.
struct ExerciseStepperWell: View {
    let label: String
    @Binding var value: Int
    var range: ClosedRange<Int>
    var step: Int = 1
    var display: (Int) -> String = { String($0) }

    var body: some View {
        VStack(spacing: VoidSpace.s2) {
            Text(label)
                .voidEyebrowSm()

            HStack(spacing: 0) {
                stepButton(icon: GapIcon.minus, enabled: value - step >= range.lowerBound, name: "Decrease \(label)") {
                    value = max(range.lowerBound, value - step)
                }

                Text(display(value))
                    .font(VoidFont.stepper)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)

                stepButton(icon: VoidIcon.plus.systemName, enabled: value + step <= range.upperBound, name: "Increase \(label)") {
                    value = min(range.upperBound, value + step)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .background(VoidColor.panel2)
        .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
        .accessibilityValue(display(value))
    }

    private func stepButton(icon: String, enabled: Bool, name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? VoidColor.text : VoidColor.text3)
                .frame(width: VoidSize.hitMin, height: VoidSize.hitMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(VoidPlainButtonStyle())
        .disabled(!enabled)
        .accessibilityLabel(name)
    }
}

/// SF Symbols the Void glyph set does not name yet.
private enum GapIcon {
    static let minus = "minus"
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
