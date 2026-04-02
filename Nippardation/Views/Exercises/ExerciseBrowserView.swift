//
//  ExerciseBrowserView.swift
//  Nippardation
//
//  Browse and filter exercises with optional selection
//

import SwiftUI

/// Wrapper view that owns its own ViewModel (for standalone use)
struct ExerciseBrowserView: View {
    @StateObject private var viewModel: ExerciseBrowserViewModel

    let onSelect: ((ExerciseLibraryItem) -> Void)?
    let onConfirmSelection: (([ExerciseLibraryItem]) -> Void)?

    init(
        isPickerMode: Bool = false,
        maxSelections: Int? = nil,
        onSelect: ((ExerciseLibraryItem) -> Void)? = nil,
        onConfirmSelection: (([ExerciseLibraryItem]) -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: ExerciseBrowserViewModel(
            isPickerMode: isPickerMode,
            maxSelections: maxSelections
        ))
        self.onSelect = onSelect
        self.onConfirmSelection = onConfirmSelection
    }

    var body: some View {
        ExerciseBrowserContent(
            viewModel: viewModel,
            onSelect: onSelect,
            onConfirmSelection: onConfirmSelection
        )
    }
}

/// Content view that uses an externally-managed ViewModel
struct ExerciseBrowserContent: View {

    @ObservedObject var viewModel: ExerciseBrowserViewModel
    @State private var showFilters = false

    let onSelect: ((ExerciseLibraryItem) -> Void)?
    let onConfirmSelection: (([ExerciseLibraryItem]) -> Void)?

    init(
        viewModel: ExerciseBrowserViewModel,
        onSelect: ((ExerciseLibraryItem) -> Void)? = nil,
        onConfirmSelection: (([ExerciseLibraryItem]) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onSelect = onSelect
        self.onConfirmSelection = onConfirmSelection
    }

    /// Returns the currently selected exercises (for use with toolbar buttons)
    var selectedExercises: [ExerciseLibraryItem] {
        viewModel.selectedExercisesList
    }

    /// Returns whether any exercises are selected
    var hasSelection: Bool {
        !viewModel.selectedExercises.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Muscle group filter bar
                MuscleGroupFilterBar(
                    selectedMuscles: viewModel.filter.muscleGroups,
                    onToggle: { muscle in
                        viewModel.toggleMuscleGroupFilter(muscle)
                    }
                )
                .padding(.bottom, AppSpacing.xs)

                // Advanced filter chips
                if viewModel.filter.hasNonMuscleFilters {
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

            // Floating selection button
            if viewModel.isPickerMode,
               !viewModel.selectedExercises.isEmpty,
               let onConfirmSelection {
                FloatingSelectionButton(
                    count: viewModel.selectedExercises.count,
                    action: {
                        onConfirmSelection(viewModel.selectedExercisesList)
                    }
                )
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .navigationTitle("Exercises")
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
                onApply: { newFilter in
                    viewModel.applyFilters(newFilter)
                }
            )
        }
        .onAppear {
            if viewModel.exercises.isEmpty {
                viewModel.loadExercises()
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

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: AppSpacing.xs) {
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
        .padding(AppSpacing.sm)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.medium)
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
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
            .padding(.horizontal, AppSpacing.md)
        }
        .padding(.bottom, AppSpacing.xs)
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
        .background(Color.appTheme.opacity(0.2))
        .foregroundColor(.appTheme)
        .cornerRadius(16)
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Exercises", systemImage: "figure.strengthtraining.traditional")
        } description: {
            if let error = viewModel.error {
                Text(error)
            } else if viewModel.filter.isEmpty {
                Text("No exercises found")
            } else {
                Text("Try adjusting your filters")
            }
        } actions: {
            if viewModel.error != nil {
                Button("Retry") {
                    viewModel.clearError()
                    viewModel.loadExercises(refresh: true)
                }
                .buttonStyle(.borderedProminent)
            } else if !viewModel.filter.isEmpty {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
            }
        }
    }

    private var exerciseList: some View {
        List {
            // Recently used section
            if !viewModel.recentlyUsedExercises.isEmpty && viewModel.searchText.isEmpty {
                Section {
                    ForEach(viewModel.recentlyUsedExercises) { exercise in
                        ExerciseSelectionRow(
                            exercise: exercise,
                            isSelected: viewModel.isPickerMode ? viewModel.isSelected(exercise) : nil,
                            onTap: {
                                if viewModel.isPickerMode {
                                    viewModel.toggleSelection(exercise)
                                } else {
                                    onSelect?(exercise)
                                }
                            }
                        )
                    }
                } header: {
                    SectionHeader(title: "Recently Used")
                }
            }

            // Library section
            Section {
                ForEach(viewModel.exercises) { exercise in
                    ExerciseSelectionRow(
                        exercise: exercise,
                        isSelected: viewModel.isPickerMode ? viewModel.isSelected(exercise) : nil,
                        onTap: {
                            if viewModel.isPickerMode {
                                viewModel.toggleSelection(exercise)
                            } else {
                                onSelect?(exercise)
                            }
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
            } header: {
                SectionHeader(title: "Library")
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Browser Mode") {
    NavigationStack {
        ExerciseBrowserView()
    }
    .withDependencies(.preview)
}

#Preview("Picker Mode") {
    NavigationStack {
        ExerciseBrowserView(isPickerMode: true)
    }
    .withDependencies(.preview)
}
