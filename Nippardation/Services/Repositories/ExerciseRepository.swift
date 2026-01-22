//
//  ExerciseRepository.swift
//  Nippardation
//
//  Concrete implementation of ExerciseRepositoryProtocol
//  Combines API calls with local Core Data caching
//

import Foundation

/// Concrete implementation of ExerciseRepositoryProtocol
/// Combines API calls with local Core Data caching
@MainActor
final class ExerciseRepository: ExerciseRepositoryProtocol {

    // MARK: - Dependencies

    private let apiService: ExerciseAPIServiceProtocol
    private let coreDataManager: CoreDataManager

    // MARK: - Cache Configuration

    /// How long cached exercises are considered fresh (in seconds)
    private let cacheExpirationSeconds: TimeInterval = 3600 // 1 hour

    /// Default page size for API requests
    private let defaultPageSize = 20

    // MARK: - Initialization

    init(
        apiService: ExerciseAPIServiceProtocol,
        coreDataManager: CoreDataManager = .shared
    ) {
        self.apiService = apiService
        self.coreDataManager = coreDataManager
    }

    // MARK: - Fetch Operations

    func fetchExercises(
        filter: ExerciseFilter?,
        page: Int,
        forceRefresh: Bool
    ) async throws -> PaginatedResult<ExerciseLibraryItem> {
        // Validate page parameter
        let validPage = max(1, page)

        // Check cache first if not forcing refresh
        if !forceRefresh {
            let cached = getCachedExercises(filter: filter)
            if !cached.isEmpty && isCacheFresh() {
                // Return paginated cache results
                let pageSize = defaultPageSize
                let startIndex = (validPage - 1) * pageSize
                let endIndex = min(startIndex + pageSize, cached.count)

                if startIndex < cached.count {
                    let pageItems = Array(cached[startIndex..<endIndex])
                    let totalPages = (cached.count + pageSize - 1) / pageSize

                    return PaginatedResult(
                        items: pageItems,
                        page: validPage,
                        totalPages: totalPages,
                        totalItems: cached.count
                    )
                }
            }
        }

        do {
            // Convert domain filter to API filter
            let apiFilters = filter.map { convertToAPIFilters($0) }

            // Calculate cursor from page (API uses cursor-based pagination)
            let cursor = validPage > 1 ? String((validPage - 1) * defaultPageSize) : nil

            // Fetch from API
            let (dtos, pagination) = try await apiService.fetchExercises(
                filters: apiFilters,
                cursor: cursor,
                limit: defaultPageSize
            )

            // Convert to domain models
            let exercises = dtos.map { ExerciseMapper.toDomain($0) }

            // Cache the results
            try? await coreDataManager.cacheExercises(exercises)

            // Calculate total pages (estimate if hasMore)
            let totalItems = pagination.hasMore ? (validPage * defaultPageSize + 1) : (validPage * defaultPageSize)
            let totalPages = pagination.hasMore ? (validPage + 1) : validPage

            return PaginatedResult(
                items: exercises,
                page: validPage,
                totalPages: totalPages,
                totalItems: totalItems
            )
        } catch {
            // If network fails, try to return cached data
            let cached = getCachedExercises(filter: filter)
            if !cached.isEmpty {
                let pageSize = defaultPageSize
                let startIndex = (validPage - 1) * pageSize
                let endIndex = min(startIndex + pageSize, cached.count)

                if startIndex < cached.count {
                    let pageItems = Array(cached[startIndex..<endIndex])
                    let totalPages = (cached.count + pageSize - 1) / pageSize

                    return PaginatedResult(
                        items: pageItems,
                        page: validPage,
                        totalPages: totalPages,
                        totalItems: cached.count
                    )
                }
            }
            throw error
        }
    }

    func fetchExercise(serverId: String, forceRefresh: Bool) async throws -> ExerciseLibraryItem {
        // Check cache first if not forcing refresh
        if !forceRefresh, let cached = getCachedExercise(serverId: serverId) {
            return cached
        }

        do {
            let dto = try await apiService.fetchExercise(id: serverId)
            let exercise = ExerciseMapper.toDomain(dto)

            // Cache the result
            try? await coreDataManager.cacheExercises([exercise])

            return exercise
        } catch {
            // Try cache as fallback
            if let cached = getCachedExercise(serverId: serverId) {
                return cached
            }
            throw RepositoryError.notFound
        }
    }

    func searchExercises(query: String, limit: Int) async throws -> [ExerciseLibraryItem] {
        // Create search filter
        let filters = ExerciseFilters(
            muscleGroups: [],
            equipment: [],
            difficulties: [],
            movementPatterns: [],
            exerciseTypes: [],
            searchQuery: query,
            includePrimaryOnly: false
        )

        do {
            let (dtos, _) = try await apiService.fetchExercises(
                filters: filters,
                cursor: nil,
                limit: limit
            )

            let exercises = dtos.map { ExerciseMapper.toDomain($0) }

            // Cache results
            try? await coreDataManager.cacheExercises(exercises)

            return exercises
        } catch {
            // Fallback to local search
            let filter = ExerciseFilter(searchText: query)
            let cached = getCachedExercises(filter: filter)
            return Array(cached.prefix(limit))
        }
    }

    // MARK: - Cache Operations

    func getCachedExercises(filter: ExerciseFilter?) -> [ExerciseLibraryItem] {
        let cached = coreDataManager.fetchCachedExercises(filter: filter)
        return cached.map { coreDataManager.toDomain($0) }
    }

    func getCachedExercise(serverId: String) -> ExerciseLibraryItem? {
        guard let cached = coreDataManager.fetchCachedExercise(serverId: serverId) else {
            return nil
        }
        return coreDataManager.toDomain(cached)
    }

    func clearCache() async throws {
        try await coreDataManager.clearExerciseCache()
    }

    // MARK: - Popular/Featured

    func fetchPopularExercises(limit: Int) async throws -> [ExerciseLibraryItem] {
        // Try API first
        do {
            let (dtos, _) = try await apiService.fetchExercises(
                filters: nil,
                cursor: nil,
                limit: limit
            )

            var exercises = dtos.map { ExerciseMapper.toDomain($0) }

            // Sort by popularity score
            exercises.sort { $0.popularityScore > $1.popularityScore }

            // Cache results
            try? await coreDataManager.cacheExercises(exercises)

            return Array(exercises.prefix(limit))
        } catch {
            // Fallback to cached popular exercises
            let cached = coreDataManager.fetchPopularCachedExercises(limit: limit)
            return cached.map { coreDataManager.toDomain($0) }
        }
    }

    func fetchExercisesByMuscle(_ muscleGroup: MuscleGroup, limit: Int) async throws -> [ExerciseLibraryItem] {
        // Create filter for muscle group
        let filters = ExerciseFilters(
            muscleGroups: [muscleGroup.rawValue],
            equipment: [],
            difficulties: [],
            movementPatterns: [],
            exerciseTypes: [],
            searchQuery: "",
            includePrimaryOnly: true
        )

        do {
            let (dtos, _) = try await apiService.fetchExercises(
                filters: filters,
                cursor: nil,
                limit: limit
            )

            let exercises = dtos.map { ExerciseMapper.toDomain($0) }

            // Cache results
            try? await coreDataManager.cacheExercises(exercises)

            return exercises
        } catch {
            // Fallback to cached exercises by muscle
            let cached = coreDataManager.fetchCachedExercisesByMuscle(muscleGroup, limit: limit)
            return cached.map { coreDataManager.toDomain($0) }
        }
    }

    // MARK: - Private Helpers

    /// Check if cache is still fresh
    private func isCacheFresh() -> Bool {
        // Find the most recent lastFetchedAt timestamp across all cached exercises
        let cached = coreDataManager.fetchCachedExercises()
        guard !cached.isEmpty else { return false }

        // Get the maximum (most recent) lastFetchedAt timestamp
        let mostRecentFetch = cached.compactMap { $0.lastFetchedAt }.max()
        guard let lastFetched = mostRecentFetch else {
            return false
        }

        return Date().timeIntervalSince(lastFetched) < cacheExpirationSeconds
    }

    /// Convert domain ExerciseFilter to API ExerciseFilters
    private func convertToAPIFilters(_ filter: ExerciseFilter) -> ExerciseFilters {
        ExerciseFilters(
            muscleGroups: Set(filter.muscleGroups.map { $0.rawValue }),
            equipment: Set(filter.equipment.map { $0.rawValue }),
            difficulties: filter.difficulty.map { Set([$0.rawValue]) } ?? [],
            movementPatterns: filter.movementPattern.map { Set([$0.rawValue]) } ?? [],
            exerciseTypes: filter.exerciseType.map { Set([$0.rawValue]) } ?? [],
            searchQuery: filter.searchText,
            includePrimaryOnly: false
        )
    }
}
