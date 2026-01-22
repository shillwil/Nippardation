//
//  SyncAPIService.swift
//  Nippardation
//
//  API service for data synchronization
//

import Foundation

final class SyncAPIService: BaseAPIService, SyncAPIServiceProtocol, @unchecked Sendable {

    override init(session: URLSession = .shared) {
        super.init(session: session)
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

        return try await performRequest(request)
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
