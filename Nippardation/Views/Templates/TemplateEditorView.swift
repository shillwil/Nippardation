//
//  TemplateEditorView.swift
//  Nippardation
//
//  Form view for creating and editing workout templates
//

import SwiftUI

struct TemplateEditorView: View {

    @StateObject private var viewModel: TemplateEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showExercisePicker = false
    @State private var editingExercise: ExerciseEditContext?

    /// Optional callback fired with the newly saved template
    private var onSave: ((Template) -> Void)?

    /// Wrapper to make exercise editing state identifiable for sheet presentation
    struct ExerciseEditContext: Identifiable {
        let id = UUID()
        let index: Int
        let exercise: TemplateEditorViewModel.EditableExercise
    }

    init(existingTemplate: Template? = nil, onSave: ((Template) -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: TemplateEditorViewModel(existingTemplate: existingTemplate))
        self.onSave = onSave
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Basic Info
                basicInfoSection

                // Summary stats
                summarySection

                // Muscle analysis chart
                MuscleAnalysisChart(distribution: viewModel.muscleGroupDistribution)

                // Exercises
                exercisesSection

                // Add Exercise Button
                addExerciseButton
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle(viewModel.isEditing ? "Edit Template" : "New Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    viewModel.save()
                }
                .fontWeight(.semibold)
                .disabled(!viewModel.isValid || viewModel.isSaving)
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            exercisePickerSheet
        }
        .sheet(item: $editingExercise) { context in
            ExerciseConfigSheet(
                exercise: context.exercise,
                onSave: { warmup, working, reps, rest, notes in
                    viewModel.updateExercise(
                        at: context.index,
                        warmupSets: warmup,
                        workingSets: working,
                        targetReps: reps,
                        restSeconds: rest,
                        notes: notes
                    )
                },
                onDelete: {
                    viewModel.removeExercise(at: context.index)
                }
            )
        }
        .onChange(of: viewModel.savedTemplate) { _, newValue in
            if let template = newValue {
                if let onSave {
                    onSave(template)
                } else {
                    dismiss()
                }
            }
        }
        .disabled(viewModel.isSaving)
        .overlay {
            if viewModel.isSaving {
                ProgressView("Saving...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppCornerRadius.medium))
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error ?? "An unknown error occurred")
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Template Name")
                .font(.subheadline)
                .fontWeight(.semibold)

            TextField("e.g., Push Day", text: $viewModel.name)
                .textFieldStyle(.roundedBorder)

            TextField("Description (optional)", text: $viewModel.description, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }

    private var summarySection: some View {
        HStack(spacing: AppSpacing.sm) {
            summaryItem(value: "\(viewModel.exercises.count)", label: "Exercises")
            summaryItem(value: "\(viewModel.totalWarmupSets)", label: "Warmup")
            summaryItem(value: "\(viewModel.totalWorkingSets)", label: "Working")
        }
    }

    private func summaryItem(value: String, label: String) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.sm)
        .cardStyle()
    }

    private var exercisesSection: some View {
        VStack(spacing: AppSpacing.sm) {
            SectionHeader(title: "Exercises (\(viewModel.exercises.count))")

            if viewModel.exercises.isEmpty {
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Add exercises to build your template")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.xl)
            } else {
                ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                    ExerciseEditorCard(
                        exercise: exercise,
                        onConfigure: {
                            editingExercise = ExerciseEditContext(index: index, exercise: exercise)
                        },
                        onDelete: {
                            viewModel.removeExercise(at: index)
                        }
                    )
                }
            }
        }
    }

    private var addExerciseButton: some View {
        Button {
            showExercisePicker = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Exercises")
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    // MARK: - Exercise Picker Sheet

    private var exercisePickerSheet: some View {
        ExercisePickerSheet(
            onCancel: {
                showExercisePicker = false
            },
            onConfirm: { selectedExercises in
                viewModel.addExercises(selectedExercises)
                showExercisePicker = false
            }
        )
    }
}

// MARK: - Exercise Picker Sheet Helper

private struct ExercisePickerSheet: View {
    let onCancel: () -> Void
    let onConfirm: ([ExerciseLibraryItem]) -> Void

    @StateObject private var browserViewModel = ExerciseBrowserViewModel(
        isPickerMode: true,
        maxSelections: nil
    )

    var body: some View {
        NavigationStack {
            ExerciseBrowserContent(
                viewModel: browserViewModel,
                onConfirmSelection: { selected in
                    onConfirm(selected)
                }
            )
                .navigationTitle("Select Exercises")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            onCancel()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add (\(browserViewModel.selectedExercises.count))") {
                            onConfirm(browserViewModel.selectedExercisesList)
                        }
                        .fontWeight(.semibold)
                        .disabled(browserViewModel.selectedExercises.isEmpty)
                    }
                }
        }
    }
}

// MARK: - Previews

#Preview("New Template") {
    NavigationStack {
        TemplateEditorView()
    }
    .withDependencies(.preview)
}

#Preview("Edit Template") {
    NavigationStack {
        TemplateEditorView(existingTemplate: MockTemplateRepository.sampleTemplates[0])
    }
    .withDependencies(.preview)
}
