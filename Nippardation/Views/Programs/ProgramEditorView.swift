//
//  ProgramEditorView.swift
//  Nippardation
//
//  Form view for creating and editing workout programs
//

import SwiftUI

struct ProgramEditorView: View {

    @StateObject private var viewModel: ProgramEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showTemplatePicker = false
    @State private var selectedWorkoutIndex: Int?

    init(existingProgram: Program? = nil) {
        self._viewModel = StateObject(wrappedValue: ProgramEditorViewModel(existingProgram: existingProgram))
    }

    var body: some View {
        Form {
            // Basic Info
            basicInfoSection

            // Duration
            durationSection

            // Workouts
            workoutsSection
        }
        .navigationTitle(viewModel.isEditing ? "Edit Program" : "New Program")
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
        .sheet(isPresented: $showTemplatePicker) {
            templatePickerSheet
        }
        .onChange(of: viewModel.savedProgram) { _, newValue in
            if newValue != nil {
                dismiss()
            }
        }
        .onAppear {
            viewModel.loadTemplates()
        }
        .disabled(viewModel.isSaving)
        .overlay {
            if viewModel.isSaving {
                ProgressView("Saving...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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
        Section("Basic Info") {
            TextField("Program Name", text: $viewModel.name)

            TextField("Description (optional)", text: $viewModel.description, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var durationSection: some View {
        Section("Schedule") {
            Stepper("Days per week: \(viewModel.daysPerWeek)", value: $viewModel.daysPerWeek, in: 1...7)

            Toggle("Indefinite program", isOn: $viewModel.isIndefinite)

            if !viewModel.isIndefinite {
                Stepper("Duration: \(viewModel.durationWeeks ?? 8) weeks",
                        value: Binding(
                            get: { viewModel.durationWeeks ?? 8 },
                            set: { viewModel.durationWeeks = $0 }
                        ),
                        in: 1...52)
            }
        }
    }

    private var workoutsSection: some View {
        Section {
            ForEach(Array(viewModel.workouts.enumerated()), id: \.element.id) { index, workout in
                workoutRow(workout, index: index)
            }
        } header: {
            Text("Workouts")
        } footer: {
            if !viewModel.workouts.allSatisfy({ $0.templateServerId != nil }) {
                Text("Assign a template to each workout day")
                    .foregroundColor(.orange)
            }
        }
    }

    @ViewBuilder
    private func workoutRow(_ workout: ProgramEditorViewModel.EditableWorkout, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Day \(index + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }

            TextField("Day Label (e.g., Push Day)", text: Binding(
                get: { viewModel.workouts[index].dayLabel },
                set: { viewModel.setLabel($0, for: index) }
            ))
            .font(.subheadline)

            Button {
                selectedWorkoutIndex = index
                showTemplatePicker = true
            } label: {
                HStack {
                    if let templateName = workout.templateName {
                        Text(templateName)
                            .foregroundColor(.primary)
                    } else {
                        Text("Select Template")
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Template Picker

    private var templatePickerSheet: some View {
        NavigationStack {
            List {
                if viewModel.isLoadingTemplates {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if viewModel.availableTemplates.isEmpty {
                    ContentUnavailableView {
                        Label("No Templates", systemImage: "doc.text")
                    } description: {
                        Text("Create a template first to use in your program")
                    }
                } else {
                    ForEach(viewModel.availableTemplates) { template in
                        Button {
                            if let index = selectedWorkoutIndex {
                                viewModel.setTemplate(template, for: index)
                            }
                            showTemplatePicker = false
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .foregroundColor(.primary)

                                HStack {
                                    Text("\(template.exerciseCount) exercises")
                                    Text("•")
                                    Text("\(template.totalWorkingSets) sets")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        showTemplatePicker = false
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("New Program") {
    NavigationStack {
        ProgramEditorView()
    }
    .withDependencies(.preview)
}

#Preview("Edit Program") {
    NavigationStack {
        ProgramEditorView(existingProgram: MockProgramRepository.samplePrograms[0])
    }
    .withDependencies(.preview)
}
