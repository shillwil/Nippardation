//
//  ProgramAPIService.swift
//  Nippardation
//
//  API service for workout program operations
//

import Foundation

final class ProgramAPIService: BaseAPIService, ProgramAPIServiceProtocol, @unchecked Sendable {

    override init(session: URLSession = .shared, authProvider: AuthTokenProviding = DefaultAuthTokenProvider.shared) {
        super.init(session: session, authProvider: authProvider)
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

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeProgramList(from: data)
    }

    func fetchProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeProgramDetail(from: data)
    }

    func fetchActiveProgram() async throws -> ActiveProgramDTO? {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs/active")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        do {
            let (data, response) = try await performRequestWithoutDecoding(request)
            try validateResponse(response, data: data)
            return try decodeActiveProgram(from: data)
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

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeProgramDetail(from: data)
    }

    func updateProgram(id: String, _ updateRequest: UpdateProgramRequest) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(updateRequest)
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeProgramDetail(from: data)
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

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeProgramDetail(from: data)
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

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeProgramDetail(from: data)
    }

    func deactivateProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("deactivate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeProgramDetail(from: data)
    }

    func advanceProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("advance")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeProgramDetail(from: data)
    }

    func resetProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("reset")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeProgramDetail(from: data)
    }

    // MARK: - Response Decoding

    private func decodeProgramList(from data: Data) throws -> (programs: [ProgramDTO], pagination: PaginationInfo) {
        if let wrappedCursor = try? decoder.decode(APIEnvelope<ProgramListCursorPayload>.self, from: data),
           let payload = wrappedCursor.data {
            return (payload.programs, payload.pagination.paginationInfo)
        }

        if let wrappedLegacy = try? decoder.decode(APIEnvelope<ProgramListResponse>.self, from: data),
           let payload = wrappedLegacy.data {
            let hasMore = payload.pagination.page < payload.pagination.totalPages
            let nextCursor = hasMore ? String(payload.pagination.page + 1) : nil
            return (payload.programs, PaginationInfo(nextCursor: nextCursor, hasMore: hasMore))
        }

        do {
            let response = try decoder.decode(ProgramListResponse.self, from: data)
            let hasMore = response.pagination.page < response.pagination.totalPages
            let nextCursor = hasMore ? String(response.pagination.page + 1) : nil
            return (response.programs, PaginationInfo(nextCursor: nextCursor, hasMore: hasMore))
        } catch {
            throw decodeFailure(error, data: data)
        }
    }

    private func decodeProgramDetail(from data: Data) throws -> ProgramDTO {
        if let wrappedDetail = try? decoder.decode(APIEnvelope<ProgramDetailResponse>.self, from: data),
           let payload = wrappedDetail.data {
            return payload.program
        }

        if let wrappedProgram = try? decoder.decode(APIEnvelope<ProgramDTO>.self, from: data),
           let payload = wrappedProgram.data {
            return payload
        }

        do {
            return try decoder.decode(ProgramDetailResponse.self, from: data).program
        } catch {
            do {
                return try decoder.decode(ProgramDTO.self, from: data)
            } catch {
                throw decodeFailure(error, data: data)
            }
        }
    }

    private func decodeActiveProgram(from data: Data) throws -> ActiveProgramDTO? {
        if let wrappedActive = try? decoder.decode(APIEnvelope<ActiveProgramDTO>.self, from: data) {
            return wrappedActive.data
        }

        if let wrappedProgram = try? decoder.decode(APIEnvelope<ProgramDTO>.self, from: data),
           let program = wrappedProgram.data {
            return ActiveProgramDTO(program: program, nextWorkout: nil, isCompleted: false)
        }

        do {
            return try decoder.decode(ActiveProgramDTO.self, from: data)
        } catch {
            do {
                let program = try decoder.decode(ProgramDTO.self, from: data)
                return ActiveProgramDTO(program: program, nextWorkout: nil, isCompleted: false)
            } catch {
                throw decodeFailure(error, data: data)
            }
        }
    }

    private func decodeFailure(_ error: Error, data: Data) -> RepositoryError {
        #if DEBUG
        print("Decoding error: \(error)")
        if let json = String(data: data, encoding: .utf8) {
            print("Response: \(json)")
        }
        #endif
        return .unknown(error)
    }
}

// MARK: - Private Response Models

private struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool?
    let data: T?
    let correlationId: String?
}

private struct CursorPaginationPayload: Decodable {
    let nextCursor: String?
    let hasMore: Bool?
    let page: Int?
    let totalPages: Int?

    var paginationInfo: PaginationInfo {
        if let hasMore {
            return PaginationInfo(nextCursor: nextCursor, hasMore: hasMore)
        }

        if let page, let totalPages {
            let hasMoreFromPage = page < totalPages
            let nextCursorFromPage = hasMoreFromPage ? String(page + 1) : nil
            return PaginationInfo(nextCursor: nextCursor ?? nextCursorFromPage, hasMore: hasMoreFromPage)
        }

        return PaginationInfo(nextCursor: nextCursor, hasMore: nextCursor != nil)
    }
}

private struct ProgramListCursorPayload: Decodable {
    let programs: [ProgramDTO]
    let pagination: CursorPaginationPayload
}
