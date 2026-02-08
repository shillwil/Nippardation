//
//  ExerciseAPIService.swift
//  Nippardation
//
//  API service for exercise-related operations
//

import Foundation

final class ExerciseAPIService: BaseAPIService, ExerciseAPIServiceProtocol, @unchecked Sendable {

    override init(session: URLSession = .shared, authProvider: AuthTokenProviding = DefaultAuthTokenProvider.shared) {
        super.init(session: session, authProvider: authProvider)
    }

    // MARK: - ExerciseAPIServiceProtocol

    func fetchExercises(
        filters: ExerciseFilters?,
        cursor: String?,
        limit: Int
    ) async throws -> (exercises: [ExerciseDTO], pagination: PaginationInfo) {
        var components = URLComponents(
            url: AppConfiguration.shared.baseURL.appendingPathComponent("api/exercises"),
            resolvingAgainstBaseURL: false
        )!

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "per_page", value: String(limit))
        ]

        // Convert cursor to page number (cursor is page index as string)
        let page = cursor.flatMap { Int($0) } ?? 1
        queryItems.append(URLQueryItem(name: "page", value: String(page)))

        // Add filter query items
        if let filters = filters {
            queryItems.append(contentsOf: filters.toQueryItems())
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw RepositoryError.unknown(nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)

        // Try new format first, then legacy, then flat format
        do {
            let newFormat = try decoder.decode(ExerciseAPIResponse.self, from: data)
            let p = newFormat.data.pagination
            let paginationInfo = PaginationInfo(
                nextCursor: p.nextCursor ?? p.page.flatMap { page in
                    let totalPages = p.totalPages ?? 0
                    return page < totalPages ? String(page + 1) : nil
                },
                hasMore: p.hasMore
            )
            return (newFormat.data.exercises, paginationInfo)
        } catch {
            // Fall through to try legacy formats
        }

        if let legacyFormat = try? decoder.decode(ExerciseLegacyResponse.self, from: data) {
            let p = legacyFormat.pagination
            let hasMore = p.page < p.totalPages
            let nextCursor = hasMore ? String(p.page + 1) : nil
            return (legacyFormat.data, PaginationInfo(nextCursor: nextCursor, hasMore: hasMore))
        }

        // Fall back to current flat format
        let flatFormat = try decoder.decode(ExerciseListResponse.self, from: data)
        let hasMore = flatFormat.pagination.page < flatFormat.pagination.totalPages
        let nextCursor = hasMore ? String(flatFormat.pagination.page + 1) : nil
        let paginationInfo = PaginationInfo(nextCursor: nextCursor, hasMore: hasMore)

        return (flatFormat.exercises, paginationInfo)
    }

    func fetchExercise(id: String) async throws -> ExerciseDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/exercises")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: ExerciseDetailResponse = try await performRequest(request)
        return response.exercise
    }

    func fetchFilterOptions() async throws -> ExerciseFilterOptionsDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/exercises/filters")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        return try await performRequest(request)
    }

    func recordUsage(exerciseId: String) async throws {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/exercises")
            .appendingPathComponent(exerciseId)
            .appendingPathComponent("usage")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
    }

}
