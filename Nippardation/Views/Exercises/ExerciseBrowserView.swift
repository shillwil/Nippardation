//
//  ExerciseBrowserView.swift
//  Nippardation
//
//  Browse and filter exercises with optional selection. The system search field sits in the
//  navigation bar drawer with the muscle chips under it, and the exercises fill an
//  inset-grouped List. Picking one exercise is a tap on its row; picking several uses the
//  List's own selection (edit mode) with an "Add (n)" confirmation in the toolbar.
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

/// Content view that uses an externally-managed ViewModel. Needs a NavigationStack from its
/// host for the search field and toolbar. In picker mode with `onConfirmSelection` set, it
/// adds the "Add (n)" confirmation item itself; the host adds Cancel.
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
        VStack(spacing: 0) {
            MuscleGroupFilterBar(
                selectedMuscles: viewModel.filter.muscleGroups,
                onToggle: { muscle in
                    viewModel.toggleMuscleGroupFilter(muscle)
                }
            )

            if viewModel.filter.hasNonMuscleFilters {
                filterChips
            }

            Group {
                if viewModel.isLoading && viewModel.exercises.isEmpty {
                    loadingView
                } else if viewModel.exercises.isEmpty {
                    emptyView
                } else {
                    exerciseList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .voidScreen()
        // Pinned in the navigation bar drawer so the muscle chips stay right under it.
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search exercises"
        )
        .textInputAutocapitalization(.never)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterButton
            }
            if viewModel.isPickerMode, let onConfirmSelection {
                ToolbarItem(placement: .confirmationAction) {
                    Button(addTitle) {
                        onConfirmSelection(viewModel.selectedExercisesList)
                    }
                    .disabled(viewModel.selectedExercises.isEmpty)
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

    // MARK: - Chrome

    /// Filters set from the chips or the Filters sheet. The search text isn't counted: it has
    /// its own field.
    private var activeFilterCount: Int {
        var filter = viewModel.filter
        filter.searchText = ""
        return filter.activeFilterCount
    }

    @ViewBuilder
    private var filterButton: some View {
        let count = activeFilterCount
        if #available(iOS 26.0, *) {
            // iOS 26 toolbar items carry a system badge.
            Button("Filters", systemImage: GapIcon.filter) {
                showFilters = true
            }
            .badge(count)
            .accessibilityValue(count > 0 ? "\(count) active" : "")
        } else {
            // Earlier toolbars draw no badge, so the glyph fills in while filters are on.
            Button("Filters", systemImage: count > 0 ? GapIcon.filterActive : GapIcon.filterIdle) {
                showFilters = true
            }
            .accessibilityValue(count > 0 ? "\(count) active" : "")
        }
    }

    private var addTitle: String {
        let count = viewModel.selectedExercises.count
        return count == 0 ? "Add" : "Add (\(count))"
    }

    /// The non-muscle filters that are on, each a button that removes it, then Clear all.
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VoidSpace.s2) {
                ForEach(Array(viewModel.filter.equipment).sorted { $0.displayName < $1.displayName }, id: \.self) { equip in
                    removeFilterButton(equip.displayName) {
                        var newFilter = viewModel.filter
                        newFilter.equipment.remove(equip)
                        viewModel.applyFilters(newFilter)
                    }
                }

                if let difficulty = viewModel.filter.difficulty {
                    removeFilterButton(difficulty.displayName) {
                        var newFilter = viewModel.filter
                        newFilter.difficulty = nil
                        viewModel.applyFilters(newFilter)
                    }
                }

                if let pattern = viewModel.filter.movementPattern {
                    removeFilterButton(pattern.displayName) {
                        var newFilter = viewModel.filter
                        newFilter.movementPattern = nil
                        viewModel.applyFilters(newFilter)
                    }
                }

                Button("Clear all") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.borderless)
                .tint(VoidColor.text2)
                .padding(.leading, VoidSpace.s1)
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.vertical, VoidSpace.s1)
        }
    }

    private func removeFilterButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: VoidSpace.s1) {
                Text(title)
                Image(systemName: VoidIcon.close.systemName)
                    .imageScale(.small)
            }
        }
        .buttonStyle(.bordered)
        .tint(VoidColor.text)
        .accessibilityLabel("Remove \(title) filter")
    }

    // MARK: - States

    private var loadingView: some View {
        ProgressView {
            Text("Loading")
                .voidEyebrowSm()
        }
        .tint(VoidColor.text2)
    }

    @ViewBuilder
    private var emptyView: some View {
        if let error = viewModel.error {
            ContentUnavailableView {
                Label("Couldn't load exercises", systemImage: GapIcon.error)
            } description: {
                Text(error)
            } actions: {
                emptyStateAction("Retry") {
                    viewModel.clearError()
                    viewModel.loadExercises(refresh: true)
                }
            }
        } else if viewModel.filter.isEmpty {
            ContentUnavailableView(
                "No exercises",
                systemImage: VoidIcon.barbell.systemName,
                description: Text("Nothing in the library yet.")
            )
        } else if activeFilterCount == 0 {
            // Only the search is narrowing the list.
            ContentUnavailableView.search(text: viewModel.filter.searchText)
        } else {
            ContentUnavailableView {
                Label("No exercises", systemImage: VoidIcon.barbell.systemName)
            } description: {
                Text("Try fewer filters.")
            } actions: {
                emptyStateAction("Clear filters") {
                    viewModel.clearFilters()
                }
            }
        }
    }

    /// An empty state's one action: plasma fill with an on-plasma label.
    private func emptyStateAction(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .foregroundStyle(VoidColor.onPlasma)
        }
        .buttonStyle(.borderedProminent)
        .tint(VoidColor.plasma)
    }

    // MARK: - List

    private var exerciseList: some View {
        List(selection: listSelection) {
            if !viewModel.recentlyUsedExercises.isEmpty && viewModel.searchText.isEmpty {
                Section("Recently used") {
                    ForEach(viewModel.recentlyUsedExercises) { exercise in
                        row(exercise)
                    }
                }
            }

            Section("Library") {
                ForEach(viewModel.exercises) { exercise in
                    row(exercise)
                }
            }

            if viewModel.hasMore {
                // Its own section so the library section keeps its rounded end.
                Section {
                    loadMoreRow
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        // Picking several: the List's edit-mode selection draws the selection circles.
        .environment(\.editMode, .constant(viewModel.isPickerMode ? .active : .inactive))
        .scrollDismissesKeyboard(.interactively)
    }

    /// Multi-select picking goes through the List's own selection. Single picks are Button
    /// rows, so the List gets no selection at all.
    private var listSelection: Binding<Set<String>>? {
        guard viewModel.isPickerMode else { return nil }
        return Binding(
            get: { viewModel.selectedExercises },
            set: { newSelection in
                // Route each change through toggleSelection so the view model keeps its
                // id → exercise map and enforces maxSelections.
                let changed = newSelection.symmetricDifference(viewModel.selectedExercises)
                guard !changed.isEmpty else { return }
                let shown = Dictionary(
                    (viewModel.recentlyUsedExercises + viewModel.exercises).map { ($0.serverId, $0) },
                    uniquingKeysWith: { first, _ in first }
                )
                for id in changed {
                    if let exercise = shown[id] {
                        viewModel.toggleSelection(exercise)
                    }
                }
            }
        )
    }

    /// Tagged with the server id, which is what the List's selection holds; the tag is
    /// inert when the List has no selection.
    private func row(_ exercise: ExerciseLibraryItem) -> some View {
        rowContent(exercise)
            .tag(exercise.serverId)
            .listRowBackground(VoidColor.panel)
            .listRowSeparatorTint(VoidColor.hairline)
    }

    @ViewBuilder
    private func rowContent(_ exercise: ExerciseLibraryItem) -> some View {
        if viewModel.isPickerMode {
            ExerciseSelectionRow(exercise: exercise)
                .accessibilityElement(children: .combine)
        } else {
            Button {
                onSelect?(exercise)
            } label: {
                ExerciseSelectionRow(exercise: exercise)
            }
        }
    }

    private var loadMoreRow: some View {
        HStack {
            Spacer()
            if viewModel.isLoadingMore {
                ProgressView()
                    .tint(VoidColor.text2)
            }
            Spacer()
        }
        .frame(height: VoidSize.pill)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .selectionDisabled()
        .onAppear {
            viewModel.loadMore()
        }
    }
}

/// SF Symbols the Void glyph set does not name yet.
private enum GapIcon {
    static let filter = "line.3.horizontal.decrease"
    static let filterIdle = "line.3.horizontal.decrease.circle"
    static let filterActive = "line.3.horizontal.decrease.circle.fill"
    static let error = "exclamationmark.triangle"
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
        ExerciseBrowserView(isPickerMode: true, onConfirmSelection: { _ in })
    }
    .withDependencies(.preview)
}
