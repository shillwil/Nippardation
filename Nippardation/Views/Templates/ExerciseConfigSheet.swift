//
//  ExerciseConfigSheet.swift
//  Nippardation
//
//  Modern configuration sheet for exercise parameters in the template editor
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
                VStack(spacing: AppSpacing.lg) {
                    // Exercise header
                    headerSection

                    // Set counters
                    setCountersSection

                    // Target reps
                    repsSection

                    // Rest timer
                    restSection

                    // Notes
                    notesSection

                    // Delete button
                    deleteSection
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Configure Exercise")
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
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(exercise.displayName)
                .font(.headline)

            if let muscles = exercise.exerciseLibraryItem?.primaryMuscles, !muscles.isEmpty {
                Text(muscles.map { $0.rawValue.capitalized }.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .cardStyle()
    }

    private var setCountersSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Sets")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: AppSpacing.md) {
                counterControl(label: "Warmup", value: $warmupSets, range: 0...5)
                counterControl(label: "Working", value: $workingSets, range: 1...10)
            }
        }
    }

    private var repsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Target Reps")
                .font(.subheadline)
                .fontWeight(.semibold)

            TextField("e.g., 8-12", text: $targetReps)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var restSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Rest Period")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: AppSpacing.xs) {
                ForEach(restOptions, id: \.self) { seconds in
                    Button {
                        restSeconds = seconds
                    } label: {
                        Text(formatRest(seconds))
                            .font(.subheadline)
                            .fontWeight(restSeconds == seconds ? .semibold : .regular)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                restSeconds == seconds
                                    ? Color.appTheme.opacity(0.15)
                                    : Color(.tertiarySystemBackground)
                            )
                            .foregroundColor(restSeconds == seconds ? .appTheme : .primary)
                            .cornerRadius(AppCornerRadius.small)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Notes")
                .font(.subheadline)
                .fontWeight(.semibold)

            TextField("Exercise notes (optional)", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }

    private var deleteSection: some View {
        Button(role: .destructive) {
            onDelete()
            dismiss()
        } label: {
            Label("Remove Exercise", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }

    // MARK: - Counter Control

    private func counterControl(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: AppSpacing.sm) {
                Button {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value.wrappedValue > range.lowerBound ? .appTheme : .secondary.opacity(0.3))
                }
                .disabled(value.wrappedValue <= range.lowerBound)

                Text("\(value.wrappedValue)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(minWidth: 32)

                Button {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value.wrappedValue < range.upperBound ? .appTheme : .secondary.opacity(0.3))
                }
                .disabled(value.wrappedValue >= range.upperBound)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.sm)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.medium)
    }

    // MARK: - Helpers

    private func formatRest(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let remaining = seconds % 60
            if remaining == 0 { return "\(minutes)m" }
            return "\(minutes):\(String(format: "%02d", remaining))"
        }
        return "\(seconds)s"
    }
}

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
