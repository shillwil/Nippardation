//
//  ExerciseAPIService.swift
//  Nippardation
//
//  API service for exercise-related operations
//

import Foundation

final class ExerciseAPIService: BaseAPIService, ExerciseAPIServiceProtocol, @unchecked Sendable {

    override init(session: URLSession = .shared) {
        super.init(session: session)
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

        let response: ExerciseListResponse = try await performRequest(request)

        // Convert PaginationDTO to PaginationInfo
        let hasMore = response.pagination.page < response.pagination.totalPages
        let nextCursor = hasMore ? String(response.pagination.page + 1) : nil
        let paginationInfo = PaginationInfo(nextCursor: nextCursor, hasMore: hasMore)

        return (response.exercises, paginationInfo)
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
