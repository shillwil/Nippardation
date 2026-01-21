//
//  ProgramAPIService.swift
//  Nippardation
//
//  API service for workout program operations
//

import Foundation

final class ProgramAPIService: ProgramAPIServiceProtocol, @unchecked Sendable {

    private let session: URLSession
    private let decoder = JSONDecoder.apiDecoder
    private let encoder = JSONEncoder.apiEncoder

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - CRUD Operations

    func fetchPrograms(
        cursor: String?,
        limit: Int
    ) async throws -> (programs: [ProgramDTO], pagination: PaginationInfo) {
        var components = URLComponents(
            url: AppConfiguration.shared.baseURL.appendingPathComponent("api/programs"),
            resolvingAgainstBaseURL: false
        )!

        let page = cursor.flatMap { Int($0) } ?? 1
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(limit))
        ]

        guard let url = components.url else {
            throw RepositoryError.unknown(nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: ProgramListResponse = try await performRequest(request)

        let hasMore = response.pagination.page < response.pagination.totalPages
        let nextCursor = hasMore ? String(response.pagination.page + 1) : nil
        let paginationInfo = PaginationInfo(nextCursor: nextCursor, hasMore: hasMore)

        return (response.programs, paginationInfo)
    }

    func fetchProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func fetchActiveProgram() async throws -> ActiveProgramDTO? {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs/active")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        do {
            return try await performRequest(request)
        } catch RepositoryError.notFound {
            // No active program is a valid state
            return nil
        }
    }

    func createProgram(_ createRequest: CreateProgramRequest) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/programs")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(createRequest)
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func updateProgram(id: String, _ updateRequest: UpdateProgramRequest) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(updateRequest)
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func updateProgramWorkouts(
        id: String,
        _ workouts: [ProgramWorkoutInput]
    ) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("workouts")

        struct WorkoutsWrapper: Encodable {
            let workouts: [ProgramWorkoutInput]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(WorkoutsWrapper(workouts: workouts))
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func deleteProgram(id: String) async throws {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try await addAuthHeader(to: &request)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    // MARK: - State Management

    func activateProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("activate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func deactivateProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("deactivate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func advanceProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("advance")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func resetProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("reset")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
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
