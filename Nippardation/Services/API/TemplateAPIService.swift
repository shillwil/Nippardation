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

        let response: TemplateListResponse = try await performRequest(request)

        let hasMore = response.pagination.page < response.pagination.totalPages
        let nextCursor = hasMore ? String(response.pagination.page + 1) : nil
        let paginationInfo = PaginationInfo(nextCursor: nextCursor, hasMore: hasMore)

        return (response.templates, paginationInfo)
    }

    func fetchTemplate(id: String) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/templates")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: TemplateDetailResponse = try await performRequest(request)
        return response.template
    }

    func createTemplate(_ createRequest: CreateTemplateRequest) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/templates")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(createRequest)
        try await addAuthHeader(to: &request)

        let response: TemplateDetailResponse = try await performRequest(request)
        return response.template
    }

    func updateTemplate(id: String, _ updateRequest: UpdateTemplateRequest) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/templates")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(updateRequest)
        try await addAuthHeader(to: &request)

        let response: TemplateDetailResponse = try await performRequest(request)
        return response.template
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

        let response: TemplateDetailResponse = try await performRequest(request)
        return response.template
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

        let response: TemplateDetailResponse = try await performRequest(request)
        return response.template
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

}
