//
//  TemplateExerciseRow.swift
//  Nippardation
//
//  Row component for displaying an exercise in a template
//

import SwiftUI

struct TemplateExerciseRow: View {

    let exercise: TemplateEditorViewModel.EditableExercise
    let onUpdate: (Int?, Int?, String?, Int?, String?) -> Void
    let onDelete: () -> Void

    @State private var showEditSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Drag handle indicator
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
                    .font(.caption)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.displayName)
                        .font(.body)
                        .fontWeight(.medium)

                    if let muscles = exercise.exerciseLibraryItem?.primaryMuscles, !muscles.isEmpty {
                        Text(muscles.map { $0.rawValue.capitalized }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }

            // Sets and reps summary
            HStack(spacing: 16) {
                if exercise.warmupSets > 0 {
                    Label("\(exercise.warmupSets) warmup", systemImage: "flame")
                }
                Label("\(exercise.workingSets) x \(exercise.targetReps)", systemImage: "number")
                Label(formatRestTime(exercise.restSeconds), systemImage: "timer")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            if !exercise.notes.isEmpty {
                Text(exercise.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showEditSheet) {
            exerciseEditSheet
        }
    }

    // MARK: - Edit Sheet

    private var exerciseEditSheet: some View {
        NavigationStack {
            ExerciseEditForm(
                exercise: exercise,
                onSave: { warmup, working, reps, rest, notes in
                    onUpdate(warmup, working, reps, rest, notes)
                    showEditSheet = false
                },
                onDelete: {
                    onDelete()
                    showEditSheet = false
                }
            )
        }
    }

    // MARK: - Helpers

    private func formatRestTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)m"
            }
            return "\(minutes):\(String(format: "%02d", remainingSeconds))"
        }
        return "\(seconds)s"
    }
}

// MARK: - Exercise Edit Form

private struct ExerciseEditForm: View {

    let exercise: TemplateEditorViewModel.EditableExercise
    let onSave: (Int, Int, String, Int, String) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var warmupSets: Int
    @State private var workingSets: Int
    @State private var targetReps: String
    @State private var restSeconds: Int
    @State private var notes: String

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
        Form {
            Section {
                Text(exercise.displayName)
                    .font(.headline)
            }

            Section("Sets") {
                Stepper("Warmup Sets: \(warmupSets)", value: $warmupSets, in: 0...5)
                Stepper("Working Sets: \(workingSets)", value: $workingSets, in: 1...10)
            }

            Section("Reps") {
                TextField("Target Reps (e.g., 8-12)", text: $targetReps)
            }

            Section("Rest") {
                Picker("Rest Period", selection: $restSeconds) {
                    Text("30 seconds").tag(30)
                    Text("60 seconds").tag(60)
                    Text("90 seconds").tag(90)
                    Text("2 minutes").tag(120)
                    Text("3 minutes").tag(180)
                    Text("4 minutes").tag(240)
                    Text("5 minutes").tag(300)
                }
            }

            Section("Notes") {
                TextField("Exercise notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove Exercise", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    onSave(warmupSets, workingSets, targetReps, restSeconds, notes)
                }
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    List {
        TemplateExerciseRow(
            exercise: TemplateEditorViewModel.EditableExercise(
                orderIndex: 0,
                exerciseServerId: "ex_001",
                exerciseLibraryItem: MockExerciseRepository.sampleExercises[0],
                warmupSets: 2,
                workingSets: 4,
                targetReps: "6-8",
                restSeconds: 180,
                notes: "Focus on mind-muscle connection"
            ),
            onUpdate: { _, _, _, _, _ in },
            onDelete: {}
        )
    }
}
