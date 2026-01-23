//
//  ExerciseBrowserView.swift
//  Nippardation
//
//  Browse and filter exercises with optional selection
//

import SwiftUI

struct ExerciseBrowserView: View {

    @StateObject private var viewModel: ExerciseBrowserViewModel
    @State private var showFilters = false

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

    /// Returns the currently selected exercises (for use with toolbar buttons)
    var selectedExercises: [ExerciseLibraryItem] {
        viewModel.selectedExercisesList
    }

    /// Confirms the current selection and calls the onConfirmSelection callback
    func confirmSelection() {
        onConfirmSelection?(viewModel.selectedExercisesList)
    }

    /// Returns whether any exercises are selected
    var hasSelection: Bool {
        !viewModel.selectedExercises.isEmpty
    }

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

    // MARK: - Subviews

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
