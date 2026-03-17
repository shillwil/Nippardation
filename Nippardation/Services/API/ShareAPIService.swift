//
//  ShareAPIService.swift
//  Nippardation
//
//  API service for sharing programs and templates
//

import Foundation

final class ShareAPIService: BaseAPIService, ShareAPIServiceProtocol, @unchecked Sendable {

    override init(session: URLSession = .shared, authProvider: AuthTokenProviding = DefaultAuthTokenProvider.shared) {
        super.init(session: session, authProvider: authProvider)
    }

    // MARK: - ShareAPIServiceProtocol

    func createShare(type: String, itemId: String) async throws -> ShareCreateResponse {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/shares")

        let body = ShareCreateRequest(type: type, itemId: itemId)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(body)
        try await addAuthHeader(to: &request)

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeCreateResponse(from: data)
    }

    func fetchShare(token: String) async throws -> ShareDetailResponse {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/shares")
            .appendingPathComponent(token)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)
        return try decodeDetailResponse(from: data)
    }

    // MARK: - Response Decoding

    private func decodeCreateResponse(from data: Data) throws -> ShareCreateResponse {
        if let wrapped = try? decoder.decode(APIEnvelope<ShareCreateResponse>.self, from: data),
           let payload = wrapped.data {
            return payload
        }

        do {
            return try decoder.decode(ShareCreateResponse.self, from: data)
        } catch {
            throw decodeFailure(error, data: data)
        }
    }

    private func decodeDetailResponse(from data: Data) throws -> ShareDetailResponse {
        if let wrapped = try? decoder.decode(APIEnvelope<ShareDetailResponse>.self, from: data),
           let payload = wrapped.data {
            return payload
        }

        do {
            return try decoder.decode(ShareDetailResponse.self, from: data)
        } catch {
            throw decodeFailure(error, data: data)
        }
    }
}
