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

    init(existingTemplate: Template? = nil) {
        self._viewModel = StateObject(wrappedValue: TemplateEditorViewModel(existingTemplate: existingTemplate))
    }

    var body: some View {
        List {
            // Basic Info
            basicInfoSection

            // Summary
            summarySection

            // Exercises
            exercisesSection

            // Add Exercise Button
            addExerciseSection
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
        .onChange(of: viewModel.savedTemplate) { _, newValue in
            if newValue != nil {
                dismiss()
            }
        }
        .disabled(viewModel.isSaving)
        .overlay {
            if viewModel.isSaving {
                ProgressView("Saving...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section("Basic Info") {
            TextField("Template Name", text: $viewModel.name)

            TextField("Description (optional)", text: $viewModel.description, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var summarySection: some View {
        Section {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(viewModel.exercises.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("\(viewModel.totalWarmupSets)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Warmup Sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("\(viewModel.totalWorkingSets)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Working Sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var exercisesSection: some View {
        Section {
            if viewModel.exercises.isEmpty {
                ContentUnavailableView {
                    Label("No Exercises", systemImage: "figure.strengthtraining.traditional")
                } description: {
                    Text("Add exercises to build your template")
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                    TemplateExerciseRow(
                        exercise: exercise,
                        onUpdate: { warmup, working, reps, rest, notes in
                            viewModel.updateExercise(
                                at: index,
                                warmupSets: warmup,
                                workingSets: working,
                                targetReps: reps,
                                restSeconds: rest,
                                notes: notes
                            )
                        },
                        onDelete: {
                            viewModel.removeExercise(at: index)
                        }
                    )
                }
                .onMove { from, to in
                    viewModel.moveExercises(from: from, to: to)
                }
                .onDelete { offsets in
                    viewModel.removeExercises(at: offsets)
                }
            }
        } header: {
            HStack {
                Text("Exercises")
                Spacer()
                EditButton()
                    .font(.caption)
            }
        }
    }

    private var addExerciseSection: some View {
        Section {
            Button {
                showExercisePicker = true
            } label: {
                Label("Add Exercises", systemImage: "plus.circle")
            }
        }
    }

    // MARK: - Exercise Picker Sheet

    private var exercisePickerSheet: some View {
        NavigationStack {
            ExerciseBrowserView(
                isPickerMode: true,
                onSelect: nil
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showExercisePicker = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Selected") {
                        // Get the selected exercises from the browser
                        // This would require passing the selected items back
                        showExercisePicker = false
                    }
                    .fontWeight(.semibold)
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
