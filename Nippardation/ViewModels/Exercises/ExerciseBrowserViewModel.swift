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
    @Published var filterOptions: ExerciseFilterOptionsDTO = .empty
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var hasMore = false
    @Published var searchText: String = ""

    // MARK: - Selection State (for picker mode)

    @Published var selectedExercises: Set<String> = []
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

        // Debounce search
        $searchText
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
        }

        guard !isLoading else { return }

        // Determine which page to fetch - only increment when loading next page
        let pageToFetch = loadingNextPage ? currentPage + 1 : currentPage

        Task {
            await taskManager.run(id: "loadExercises") { [weak self] in
                guard let self = self else { return }

                await MainActor.run {
                    if refresh {
                        self.isLoading = true
                    } else {
                        self.isLoadingMore = true
                    }
                }

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

    /// Loads filter options from the repository
    func loadFilterOptions() {
        // For now, build filter options from enums
        // In future, this could fetch from API
        filterOptions = ExerciseFilterOptionsDTO(
            muscleGroups: MuscleGroup.allCases.map { muscle in
                FilterOptionDTO(
                    value: muscle.rawValue,
                    label: muscle.rawValue.capitalized,
                    count: 0
                )
            },
            difficulties: Difficulty.allCases.map { difficulty in
                FilterOptionDTO(
                    value: difficulty.rawValue,
                    label: difficulty.displayName,
                    count: 0
                )
            },
            equipment: Equipment.allCases.map { equipment in
                FilterOptionDTO(
                    value: equipment.rawValue,
                    label: equipment.displayName,
                    count: 0
                )
            },
            movementPatterns: MovementPattern.allCases.map { pattern in
                FilterOptionDTO(
                    value: pattern.rawValue,
                    label: pattern.displayName,
                    count: 0
                )
            },
            exerciseTypes: ExerciseCategory.allCases.map { category in
                FilterOptionDTO(
                    value: category.rawValue,
                    label: category.displayName,
                    count: 0
                )
            }
        )
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
        } else {
            if let max = maxSelections, selectedExercises.count >= max {
                return // Don't allow more selections
            }
            selectedExercises.insert(exercise.serverId)
        }
    }

    /// Checks if an exercise is selected
    /// - Parameter exercise: The exercise to check
    /// - Returns: true if selected
    func isSelected(_ exercise: ExerciseLibraryItem) -> Bool {
        selectedExercises.contains(exercise.serverId)
    }

    /// Returns the list of selected exercise items
    var selectedExercisesList: [ExerciseLibraryItem] {
        exercises.filter { selectedExercises.contains($0.serverId) }
    }

    /// Clears the current error message
    func clearError() {
        error = nil
    }
}
