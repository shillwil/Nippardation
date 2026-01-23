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

/// A separate view to properly manage the ExerciseBrowserView state for selection
private struct ExercisePickerSheet: View {
    let onCancel: () -> Void
    let onConfirm: ([ExerciseLibraryItem]) -> Void

    @StateObject private var browserViewModel = ExerciseBrowserViewModel(
        isPickerMode: true,
        maxSelections: nil
    )

    var body: some View {
        NavigationStack {
            ExerciseBrowserViewContent(viewModel: browserViewModel)
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

/// Internal view that uses an existing ExerciseBrowserViewModel
private struct ExerciseBrowserViewContent: View {
    @ObservedObject var viewModel: ExerciseBrowserViewModel
    @State private var showFilters = false

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            // Filter chips
            if viewModel.filter.activeFilterCount > 0 {
                filterChips
            }

            // Exercise list
            if viewModel.isLoading && viewModel.exercises.isEmpty {
                Spacer()
                ProgressView("Loading exercises...")
                Spacer()
            } else if viewModel.exercises.isEmpty {
                emptyView
            } else {
                exerciseList
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: viewModel.filter.activeFilterCount > 0
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            ExerciseFilterSheet(
                filter: viewModel.filter,
                filterOptions: viewModel.filterOptions,
                onApply: { newFilter in
                    viewModel.applyFilters(newFilter)
                }
            )
        }
        .onAppear {
            if viewModel.exercises.isEmpty {
                viewModel.loadExercises()
                viewModel.loadFilterOptions()
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search exercises", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding()
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Array(viewModel.filter.muscleGroups), id: \.self) { muscle in
                    filterChip(muscle.rawValue.capitalized) {
                        var newFilter = viewModel.filter
                        newFilter.muscleGroups.remove(muscle)
                        viewModel.applyFilters(newFilter)
                    }
                }

                ForEach(Array(viewModel.filter.equipment), id: \.self) { equip in
                    filterChip(equip.displayName) {
                        var newFilter = viewModel.filter
                        newFilter.equipment.remove(equip)
                        viewModel.applyFilters(newFilter)
                    }
                }

                if let difficulty = viewModel.filter.difficulty {
                    filterChip(difficulty.displayName) {
                        var newFilter = viewModel.filter
                        newFilter.difficulty = nil
                        viewModel.applyFilters(newFilter)
                    }
                }

                if let pattern = viewModel.filter.movementPattern {
                    filterChip(pattern.displayName) {
                        var newFilter = viewModel.filter
                        newFilter.movementPattern = nil
                        viewModel.applyFilters(newFilter)
                    }
                }

                Button("Clear All") {
                    viewModel.clearFilters()
                }
                .font(.caption)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    private func filterChip(_ value: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(value)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Exercises", systemImage: "figure.strengthtraining.traditional")
        } description: {
            Text(viewModel.filter.isEmpty ? "No exercises found" : "Try adjusting your filters")
        } actions: {
            if !viewModel.filter.isEmpty {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
            }
        }
    }

    private var exerciseList: some View {
        List {
            ForEach(viewModel.exercises) { exercise in
                ExercisePickerRow(
                    exercise: exercise,
                    isSelected: viewModel.isSelected(exercise),
                    onTap: {
                        viewModel.toggleSelection(exercise)
                    }
                )
            }

            if viewModel.hasMore {
                HStack {
                    Spacer()
                    if viewModel.isLoadingMore {
                        ProgressView()
                    }
                    Spacer()
                }
                .onAppear {
                    viewModel.loadMore()
                }
            }
        }
        .listStyle(.plain)
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
