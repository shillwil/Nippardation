//
//  SyncAPIService.swift
//  Nippardation
//
//  API service for data synchronization
//

import Foundation

final class SyncAPIService: BaseAPIService, SyncAPIServiceProtocol, @unchecked Sendable {

    override init(session: URLSession = .shared, authProvider: AuthTokenProviding = DefaultAuthTokenProvider.shared) {
        super.init(session: session, authProvider: authProvider)
    }

    // MARK: - SyncAPIServiceProtocol

    func sync(payload: SyncRequestDTO) async throws -> SyncResponseDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/sync")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(payload)
        try await addAuthHeader(to: &request)

        // Sync operations may take longer
        request.timeoutInterval = 60

        // Try new wrapped format first, fall back to flat format
        let (data, response) = try await performRequestWithoutDecoding(request)
        try validateResponse(response, data: data)

        if let wrapped = try? decoder.decode(SyncAPIResponse.self, from: data) {
            return wrapped.data
        }

        // Fall back to flat SyncResponseDTO (legacy)
        return try decoder.decode(SyncResponseDTO.self, from: data)
    }

    // MARK: - Override for Sync-specific response handling

    override func validateResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.unknown(nil)
        }

        // 409 Conflict is valid for sync - let caller handle via response data
        if httpResponse.statusCode == 409 {
            return
        }

        try super.validateResponse(response, data: data)
    }
}
