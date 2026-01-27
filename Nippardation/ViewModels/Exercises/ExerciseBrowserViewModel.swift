//
//  ExerciseBrowserViewModel.swift
//  Nippardation
//
//  ViewModel for browsing and filtering exercises
//

import Foundation
import Combine

@MainActor
final class ExerciseBrowserViewModel: ObservableObject {

    // MARK: - Published State

    @Published var exercises: [ExerciseLibraryItem] = []
    @Published var filter = ExerciseFilter()
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var hasMore = false
    @Published var searchText: String = ""

    // MARK: - Selection State (for picker mode)

    @Published var selectedExercises: Set<String> = []
    private var selectedExerciseItems: [String: ExerciseLibraryItem] = [:]
    let isPickerMode: Bool
    let maxSelections: Int?

    // MARK: - Dependencies

    private let exerciseRepository: any ExerciseRepositoryProtocol
    private let taskManager = TaskManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Pagination State

    private var currentPage = 1
    private let pageSize = 30

    // MARK: - Initialization

    init(
        isPickerMode: Bool = false,
        maxSelections: Int? = nil,
        preselectedExerciseIds: Set<String> = [],
        exerciseRepository: (any ExerciseRepositoryProtocol)? = nil
    ) {
        self.isPickerMode = isPickerMode
        self.maxSelections = maxSelections
        self.selectedExercises = preselectedExerciseIds
        self.exerciseRepository = exerciseRepository ?? DependencyContainer.shared.exerciseRepository

        // Debounce search - dropFirst to avoid initial empty value triggering a load
        $searchText
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.filter.searchText = query
                self?.loadExercises(refresh: true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Loads exercises from the repository
    /// - Parameters:
    ///   - refresh: If true, reloads from the beginning
    ///   - loadingNextPage: If true, loads the next page (currentPage + 1)
    func loadExercises(refresh: Bool = false, loadingNextPage: Bool = false) {
        if refresh {
            currentPage = 1
            exercises = []
            // Cancel any in-progress request for refresh (e.g., new search query)
            // This ensures fresh search results match the current search text
            Task { await taskManager.cancel(id: "loadExercises") }
            isLoading = false
            isLoadingMore = false
        }

        guard !isLoading && !isLoadingMore else { return }

        // Determine which page to fetch - only increment when loading next page
        let pageToFetch = loadingNextPage ? currentPage + 1 : currentPage

        // Set loading state synchronously to prevent race conditions
        // Use isLoading for initial load or refresh, isLoadingMore for pagination
        if refresh || exercises.isEmpty {
            isLoading = true
        } else {
            isLoadingMore = true
        }

        Task {
            await taskManager.run(id: "loadExercises") { [weak self] in
                guard let self = self else { return }

                do {
                    let result = try await self.exerciseRepository.fetchExercises(
                        filter: self.filter.isEmpty ? nil : self.filter,
                        page: pageToFetch,
                        forceRefresh: refresh
                    )

                    await MainActor.run {
                        if refresh {
                            self.exercises = result.items
                        } else {
                            self.exercises.append(contentsOf: result.items)
                        }
                        // Populate selectedExerciseItems for any preselected exercises now loaded
                        for exercise in result.items where self.selectedExercises.contains(exercise.serverId) {
                            if self.selectedExerciseItems[exercise.serverId] == nil {
                                self.selectedExerciseItems[exercise.serverId] = exercise
                            }
                        }
                        // Only update currentPage on success
                        self.currentPage = result.page
                        self.hasMore = result.hasNextPage
                        self.error = nil
                        self.isLoading = false
                        self.isLoadingMore = false
                    }
                } catch {
                    await MainActor.run {
                        // Fall back to cached exercises
                        if refresh {
                            let cached = self.exerciseRepository.getCachedExercises(filter: self.filter)
                            if !cached.isEmpty {
                                self.exercises = cached
                                // Populate selectedExerciseItems for any preselected exercises
                                for exercise in cached where self.selectedExercises.contains(exercise.serverId) {
                                    if self.selectedExerciseItems[exercise.serverId] == nil {
                                        self.selectedExerciseItems[exercise.serverId] = exercise
                                    }
                                }
                            }
                        }
                        // Don't update currentPage on error - allows retry of same page
                        self.error = error.localizedDescription
                        self.isLoading = false
                        self.isLoadingMore = false
                    }
                }
            }
        }
    }

    /// Loads more exercises if available
    func loadMore() {
        guard hasMore && !isLoading && !isLoadingMore else { return }
        // Don't increment page here - it's updated on success in loadExercises
        loadExercises(loadingNextPage: true)
    }

    /// Applies new filters and reloads
    /// - Parameter newFilter: The new filter to apply
    func applyFilters(_ newFilter: ExerciseFilter) {
        filter = newFilter
        // Sync searchText with filter to keep UI in sync
        searchText = newFilter.searchText
        loadExercises(refresh: true)
    }

    /// Clears all filters
    func clearFilters() {
        filter.reset()
        searchText = ""
        loadExercises(refresh: true)
    }

    // MARK: - Selection (Picker Mode)

    /// Toggles selection of an exercise
    /// - Parameter exercise: The exercise to toggle
    func toggleSelection(_ exercise: ExerciseLibraryItem) {
        if selectedExercises.contains(exercise.serverId) {
            selectedExercises.remove(exercise.serverId)
            selectedExerciseItems.removeValue(forKey: exercise.serverId)
        } else {
            if let max = maxSelections, selectedExercises.count >= max {
                return // Don't allow more selections
            }
            selectedExercises.insert(exercise.serverId)
            selectedExerciseItems[exercise.serverId] = exercise
        }
    }

    /// Checks if an exercise is selected
    /// - Parameter exercise: The exercise to check
    /// - Returns: true if selected
    func isSelected(_ exercise: ExerciseLibraryItem) -> Bool {
        selectedExercises.contains(exercise.serverId)
    }

    /// Returns the list of selected exercise items (preserves selections even when filtered)
    var selectedExercisesList: [ExerciseLibraryItem] {
        Array(selectedExerciseItems.values)
    }

    /// Clears the current error message
    func clearError() {
        error = nil
    }
}
