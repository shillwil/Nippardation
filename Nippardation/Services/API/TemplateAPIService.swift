//
//  TemplateAPIService.swift
//  Nippardation
//
//  API service for workout template operations
//

import Foundation

final class TemplateAPIService: BaseAPIService, TemplateAPIServiceProtocol, @unchecked Sendable {

    override init(session: URLSession = .shared, authProvider: AuthTokenProviding = DefaultAuthTokenProvider.shared) {
        super.init(session: session, authProvider: authProvider)
    }

    // MARK: - TemplateAPIServiceProtocol

    func fetchTemplates(
        cursor: String?,
        limit: Int
    ) async throws -> (templates: [TemplateDTO], pagination: PaginationInfo) {
        var components = URLComponents(
            url: AppConfiguration.shared.baseURL.appendingPathComponent("api/templates"),
            resolvingAgainstBaseURL: false
        )!

        var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
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
        return try decodeTemplateList(from: data)
    }

    func fetchTemplate(id: String) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/templates")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeTemplateDetail(from: data)
    }

    func createTemplate(_ createRequest: CreateTemplateRequest) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/templates")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(createRequest)
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeTemplateDetail(from: data)
    }

    func updateTemplate(id: String, _ updateRequest: UpdateTemplateRequest) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/templates")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(updateRequest)
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeTemplateDetail(from: data)
    }

    func updateTemplateExercises(
        id: String,
        _ exercises: [TemplateExerciseInput]
    ) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/templates")
            .appendingPathComponent(id)
            .appendingPathComponent("exercises")

        struct ExercisesWrapper: Encodable {
            let exercises: [TemplateExerciseInput]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(ExercisesWrapper(exercises: exercises))
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeTemplateDetail(from: data)
    }

    func cloneTemplate(id: String, newName: String?) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/templates")
            .appendingPathComponent(id)
            .appendingPathComponent("clone")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let name = newName {
            struct NameWrapper: Encodable {
                let name: String
            }
            request.httpBody = try encoder.encode(NameWrapper(name: name))
        }
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeTemplateDetail(from: data)
    }

    func deleteTemplate(id: String) async throws {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/templates")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)

        // Check for 409 Conflict (template in use by program)
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 409 {
            throw RepositoryError.syncConflict(localId: id, remoteId: nil)
        }

        try validateResponse(response, data: data)
    }

    // MARK: - Response Decoding

    private func decodeTemplateList(from data: Data) throws -> (templates: [TemplateDTO], pagination: PaginationInfo) {
        if let wrappedCursor = try? decoder.decode(TemplateAPIEnvelope<TemplateListCursorPayload>.self, from: data),
           let payload = wrappedCursor.data {
            return (payload.templates, payload.pagination.paginationInfo)
        }

        if let wrappedLegacy = try? decoder.decode(TemplateAPIEnvelope<TemplateListResponse>.self, from: data),
           let payload = wrappedLegacy.data {
            let hasMore = payload.pagination.page < payload.pagination.totalPages
            let nextCursor = hasMore ? String(payload.pagination.page + 1) : nil
            return (payload.templates, PaginationInfo(nextCursor: nextCursor, hasMore: hasMore))
        }

        do {
            let response = try decoder.decode(TemplateListResponse.self, from: data)
            let hasMore = response.pagination.page < response.pagination.totalPages
            let nextCursor = hasMore ? String(response.pagination.page + 1) : nil
            return (response.templates, PaginationInfo(nextCursor: nextCursor, hasMore: hasMore))
        } catch {
            throw decodeFailure(error, data: data)
        }
    }

    private func decodeTemplateDetail(from data: Data) throws -> TemplateDTO {
        if let wrappedDetail = try? decoder.decode(TemplateAPIEnvelope<TemplateDetailResponse>.self, from: data),
           let payload = wrappedDetail.data {
            return payload.template
        }

        if let wrappedTemplate = try? decoder.decode(TemplateAPIEnvelope<TemplateDTO>.self, from: data),
           let payload = wrappedTemplate.data {
            return payload
        }

        do {
            return try decoder.decode(TemplateDetailResponse.self, from: data).template
        } catch {
            do {
                return try decoder.decode(TemplateDTO.self, from: data)
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

private struct TemplateAPIEnvelope<T: Decodable>: Decodable {
    let success: Bool?
    let data: T?
    let correlationId: String?
}

private struct TemplateCursorPaginationPayload: Decodable {
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

private struct TemplateListCursorPayload: Decodable {
    let templates: [TemplateDTO]
    let pagination: TemplateCursorPaginationPayload
}
