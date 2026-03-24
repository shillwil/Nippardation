//
//  GeneratedProgramPreviewView.swift
//  Nippardation
//
//  Preview and edit screen for an AI-generated program before saving
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
        onSave: @escaping () -> Void,
        onDiscard: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: GeneratedProgramPreviewViewModel(
            program: program,
            metadata: metadata
        ))
        self.onSave = onSave
        self.onDiscard = onDiscard
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // AI header banner
                headerBanner

                // Editable program info
                programInfoSection

                // Workout list
                ForEach(Array(viewModel.workouts.enumerated()), id: \.element.id) { workoutIndex, workout in
                    workoutSection(workout: workout, workoutIndex: workoutIndex)
                }
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle("Review Program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Discard") {
                    onDiscard()
                }
                .foregroundColor(.red)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.save()
                } label: {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "sparkles")
                        Text("Save")
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AIColors.gradient)
                }
                .disabled(viewModel.isSaving)
            }
        }
        .overlay {
            if viewModel.isSaving {
                ProgressView("Saving...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppCornerRadius.medium))
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

    // MARK: - Header Banner

    private var headerBanner: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                Text("AI Generated")
                    .font(.headline)
                Spacer()
                if let time = viewModel.generationTimeFormatted {
                    PillBadge(text: "Generated in \(time)", color: AIColors.accent, style: .tinted)
                }
            }
            .foregroundStyle(AIColors.gradient)

            HStack(spacing: AppSpacing.sm) {
                PillBadge(
                    text: "\(viewModel.originalProgram.daysPerWeek) days/wk",
                    color: .blue,
                    style: .tinted
                )
                PillBadge(
                    text: "\(viewModel.totalExercises) exercises",
                    color: .green,
                    style: .tinted
                )
                if let weeks = viewModel.originalProgram.durationWeeks {
                    PillBadge(
                        text: "\(weeks) weeks",
                        color: .purple,
                        style: .tinted
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .aiGradientCardStyle()
    }

    // MARK: - Program Info

    private var programInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Program Details")
                .font(.headline)

            TextField("Program Name", text: $viewModel.programName)
                .textFieldStyle(.roundedBorder)
                .font(.body.bold())

            TextField("Description (optional)", text: $viewModel.programDescription, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }

    // MARK: - Workout Section

    private func workoutSection(workout: GeneratedProgramPreviewViewModel.EditableWorkout, workoutIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(workout.dayLabel)
                    .font(.headline)
                Spacer()
                Text("\(workout.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { exerciseIndex, exercise in
                EditableExerciseRow(
                    exercise: Binding(
                        get: { viewModel.workouts[workoutIndex].exercises[exerciseIndex] },
                        set: { viewModel.workouts[workoutIndex].exercises[exerciseIndex] = $0 }
                    ),
                    onDelete: {
                        viewModel.removeExercise(workoutIndex: workoutIndex, exerciseIndex: exerciseIndex)
                    }
                )
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
}

// MARK: - Editable Exercise Row

struct EditableExerciseRow: View {
    @Binding var exercise: GeneratedProgramPreviewViewModel.EditableExercise
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary.opacity(0.5))
                        .font(.body)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: AppSpacing.md) {
                editableField("Sets", value: $exercise.workingSets)
                editableField("Reps", text: $exercise.targetReps)
                editableField("Rest", value: $exercise.restSeconds, suffix: "s")
            }
        }
        .padding(AppSpacing.sm)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.small)
    }

    private func editableField(_ label: String, value: Binding<Int>, suffix: String = "") -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            HStack(spacing: 2) {
                TextField("", value: value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 45)
                    .font(.caption)
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func editableField(_ label: String, text: Binding<String>) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            TextField("", text: text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 55)
                .font(.caption)
        }
    }
}

#Preview {
    let program = AIGeneratedProgramMapper.toDomain(MockAIAPIService.sampleGenerateResponse.program)
    NavigationStack {
        GeneratedProgramPreviewView(
            program: program,
            metadata: MockAIAPIService.sampleGenerateResponse.generation,
            onSave: {},
            onDiscard: {}
        )
    }
    .withDependencies(.preview)
}
