//
//  ExerciseBrowserView.swift
//  Nippardation
//
//  Browse and filter exercises with optional selection. Void chrome: hull background,
//  squared search well, 28pt muscle chips, hairline rows, plasma selection checks,
//  and a content-sized "Add (n)" CTA when picking.
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

    private var showsFloatingButton: Bool {
        viewModel.isPickerMode && !viewModel.selectedExercises.isEmpty && onConfirmSelection != nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                VoidTextField(
                    placeholder: "Search exercises",
                    text: $viewModel.searchText,
                    icon: .search,
                    autocapitalization: .never
                )
                .padding(.horizontal, VoidSpace.insetCard)
                .padding(.top, VoidSpace.s2)
                .padding(.bottom, VoidSpace.s3)

                MuscleGroupFilterBar(
                    selectedMuscles: viewModel.filter.muscleGroups,
                    onToggle: { muscle in
                        viewModel.toggleMuscleGroupFilter(muscle)
                    }
                )

                if viewModel.filter.hasNonMuscleFilters {
                    filterChips
                        .padding(.top, VoidSpace.s2)
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
                .padding(.top, VoidSpace.s1)
            }

            if showsFloatingButton, let onConfirmSelection {
                FloatingSelectionButton(
                    count: viewModel.selectedExercises.count,
                    action: {
                        onConfirmSelection(viewModel.selectedExercisesList)
                    }
                )
                .padding(.bottom, VoidSpace.s6)
            }
        }
        .navigationTitle("Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .voidScreen()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterButton
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

    private var filterButton: some View {
        Button {
            showFilters = true
        } label: {
            Image(systemName: GapIcon.filter)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(VoidColor.text)
                .overlay(alignment: .topTrailing) {
                    if viewModel.filter.activeFilterCount > 0 {
                        PlasmaDot(size: 6)
                            .offset(x: 5, y: -4)
                    }
                }
        }
        .accessibilityLabel("Filters")
        .accessibilityValue(viewModel.filter.activeFilterCount > 0 ? "\(viewModel.filter.activeFilterCount) active" : "")
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VoidSpace.s2) {
                ForEach(Array(viewModel.filter.equipment).sorted { $0.displayName < $1.displayName }, id: \.self) { equip in
                    VoidSquareChip(text: equip.displayName, isSelected: true, trailingIcon: .close) {
                        var newFilter = viewModel.filter
                        newFilter.equipment.remove(equip)
                        viewModel.applyFilters(newFilter)
                    }
                }

                if let difficulty = viewModel.filter.difficulty {
                    VoidSquareChip(text: difficulty.displayName, isSelected: true, trailingIcon: .close) {
                        var newFilter = viewModel.filter
                        newFilter.difficulty = nil
                        viewModel.applyFilters(newFilter)
                    }
                }

                if let pattern = viewModel.filter.movementPattern {
                    VoidSquareChip(text: pattern.displayName, isSelected: true, trailingIcon: .close) {
                        var newFilter = viewModel.filter
                        newFilter.movementPattern = nil
                        viewModel.applyFilters(newFilter)
                    }
                }

                Button {
                    viewModel.clearFilters()
                } label: {
                    Text("Clear all")
                        .font(VoidFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(VoidColor.text2)
                        .frame(minWidth: VoidSize.hitMin, minHeight: VoidSize.hitMin)
                        .contentShape(Rectangle())
                }
                .buttonStyle(VoidPlainButtonStyle())
                .padding(.leading, VoidSpace.s1)
            }
            .padding(.horizontal, VoidSpace.insetCard)
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: VoidSpace.s3) {
            ProgressView()
                .tint(VoidColor.text2)
            Text("Loading")
                .voidEyebrowSm()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: VoidSpace.s4) {
            VoidPlaceholder(eyebrow: "No exercises", caption: emptyCaption)

            if viewModel.error != nil {
                VoidPillButton(title: "Retry") {
                    viewModel.clearError()
                    viewModel.loadExercises(refresh: true)
                }
            } else if !viewModel.filter.isEmpty {
                VoidPillButton(title: "Clear filters") {
                    viewModel.clearFilters()
                }
            }
        }
        .padding(.horizontal, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyCaption: String {
        if let error = viewModel.error {
            return error
        }
        if viewModel.filter.isEmpty {
            return "Nothing in the library yet."
        }
        return "Try fewer filters."
    }

    // MARK: - List

    private var exerciseList: some View {
        List {
            if !viewModel.recentlyUsedExercises.isEmpty && viewModel.searchText.isEmpty {
                Section {
                    ForEach(viewModel.recentlyUsedExercises) { exercise in
                        row(exercise)
                    }
                } header: {
                    sectionHeader("Recently used")
                }
            }

            Section {
                ForEach(viewModel.exercises) { exercise in
                    row(exercise)
                }

                if viewModel.hasMore {
                    HStack {
                        Spacer()
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .tint(VoidColor.text2)
                        }
                        Spacer()
                    }
                    .frame(height: VoidSize.pill)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .onAppear {
                        viewModel.loadMore()
                    }
                }
            } header: {
                sectionHeader("Library")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listSectionSeparator(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .contentMargins(.bottom, showsFloatingButton ? VoidSize.cta + VoidSpace.s6 * 2 : 0, for: .scrollContent)
    }

    private func row(_ exercise: ExerciseLibraryItem) -> some View {
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
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .voidEyebrowSm()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, VoidSpace.insetText)
            .padding(.top, VoidSpace.s3)
            .padding(.bottom, VoidSpace.s2)
            .background(VoidColor.hull)
            .listRowInsets(EdgeInsets())
    }
}

/// SF Symbols the Void glyph set does not name yet.
private enum GapIcon {
    static let filter = "line.3.horizontal.decrease"
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
