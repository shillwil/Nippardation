//
//  ProgramAPIService.swift
//  Nippardation
//
//  API service for workout program operations
//

import Foundation

final class ProgramAPIService: BaseAPIService, ProgramAPIServiceProtocol, @unchecked Sendable {

    override init(session: URLSession = .shared) {
        super.init(session: session)
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

        let (data, response) = try await performRequestWithoutDecoding(request)
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

}
