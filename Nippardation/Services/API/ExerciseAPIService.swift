//
//  ExerciseAPIService.swift
//  Nippardation
//
//  API service for exercise-related operations
//

import Foundation

final class ExerciseAPIService: ExerciseAPIServiceProtocol, @unchecked Sendable {

    private let session: URLSession
    private let decoder = JSONDecoder.apiDecoder

    init(session: URLSession = .shared) {
        self.session = session
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

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Private Helpers

    private func addAuthHeader(to request: inout URLRequest) async throws {
        guard let token = try await AuthManager.shared.getIDToken() else {
            throw RepositoryError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw RepositoryError.networkUnavailable
            case .timedOut:
                throw RepositoryError.timeout
            default:
                throw RepositoryError.unknown(error)
            }
        }

        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("Decoding error: \(error)")
            if let json = String(data: data, encoding: .utf8) {
                print("Response: \(json)")
            }
            #endif
            throw RepositoryError.unknown(error)
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.unknown(nil)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw RepositoryError.unauthorized
        case 404:
            throw RepositoryError.notFound
        case 422:
            let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Validation failed"
            throw RepositoryError.validationError(message)
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Double($0) }
            throw RepositoryError.rateLimited(retryAfter: retryAfter)
        case 400...499:
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            throw RepositoryError.serverError(statusCode: httpResponse.statusCode, message: message)
        case 500...599:
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            throw RepositoryError.serverError(statusCode: httpResponse.statusCode, message: message)
        default:
            throw RepositoryError.unknown(nil)
        }
    }
}
