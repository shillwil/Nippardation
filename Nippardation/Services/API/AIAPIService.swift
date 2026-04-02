//
//  AIAPIService.swift
//  Nippardation
//
//  API service for AI-powered program generation
//

import Foundation

final class AIAPIService: BaseAPIService, AIAPIServiceProtocol, @unchecked Sendable {

    override init(session: URLSession = .shared, authProvider: AuthTokenProviding = DefaultAuthTokenProvider.shared) {
        super.init(session: session, authProvider: authProvider)
    }

    // MARK: - AIAPIServiceProtocol

    func generateProgram(_ request: GenerateProgramRequest) async throws -> GenerateProgramResponse {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/ai/generate-program")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try encoder.encode(request)
        urlRequest.timeoutInterval = 120 // Generation can take 30-60s+ on the backend
        try await addAuthHeader(to: &urlRequest)

        let (data, response) = try await performRequestWithoutDecoding(urlRequest)

        // Custom error handling: parse the backend's JSON error structure
        // to extract the human-readable message instead of showing raw JSON
        do {
            try validateResponse(response, data: data)
        } catch {
            throw Self.parseAIError(from: data) ?? error
        }

        return try decodeGenerateResponse(from: data)
    }

    func fetchGenerationStatus() async throws -> GenerationStatusResponse {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/ai/generation-status")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        try await addAuthHeader(to: &urlRequest)

        let (data, response) = try await performRequestWithoutDecoding(urlRequest)
        try validateResponse(response, data: data)
        return try decodeStatusResponse(from: data)
    }

    func saveStrengthProfile(_ request: StrengthProfileRequest) async throws {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/ai/strength-profile")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.httpBody = try encoder.encode(request)
        try await addAuthHeader(to: &urlRequest)

        let (data, response) = try await performRequestWithoutDecoding(urlRequest)
        try validateResponse(response, data: data)
    }

    func fetchStrengthProfile() async throws -> StrengthProfileResponse {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/ai/strength-profile")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        try await addAuthHeader(to: &urlRequest)

        let (data, response) = try await performRequestWithoutDecoding(urlRequest)
        try validateResponse(response, data: data)
        return try decodeProfileResponse(from: data)
    }

    // MARK: - Error Parsing

    /// Parses the backend's structured error JSON to extract a human-readable message.
    /// Backend returns: {"success":false,"message":"...","correlationId":"...","retryable":true/false}
    private static func parseAIError(from data: Data?) -> RepositoryError? {
        guard let data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, !success,
              let message = json["message"] as? String else {
            return nil
        }

        #if DEBUG
        print("[AIAPIService] Error response: \(json)")
        #endif

        let retryable = json["retryable"] as? Bool ?? false
        // Use 503 for retryable so RepositoryError.isRetryable returns true (statusCode >= 500)
        let statusCode = retryable ? 503 : 500
        return .serverError(statusCode: statusCode, message: message)
    }

    // MARK: - Response Decoding

    private func decodeGenerateResponse(from data: Data) throws -> GenerateProgramResponse {
        // Try wrapped envelope first
        if let wrapped = try? decoder.decode(APIEnvelope<GenerateProgramResponse>.self, from: data),
           let payload = wrapped.data {
            return payload
        }

        do {
            return try decoder.decode(GenerateProgramResponse.self, from: data)
        } catch {
            throw decodeFailure(error, data: data)
        }
    }

    private func decodeStatusResponse(from data: Data) throws -> GenerationStatusResponse {
        if let wrapped = try? decoder.decode(APIEnvelope<GenerationStatusResponse>.self, from: data),
           let payload = wrapped.data {
            return payload
        }

        do {
            return try decoder.decode(GenerationStatusResponse.self, from: data)
        } catch {
            throw decodeFailure(error, data: data)
        }
    }

    private func decodeProfileResponse(from data: Data) throws -> StrengthProfileResponse {
        if let wrapped = try? decoder.decode(APIEnvelope<StrengthProfileResponse>.self, from: data),
           let payload = wrapped.data {
            return payload
        }

        do {
            return try decoder.decode(StrengthProfileResponse.self, from: data)
        } catch {
            throw decodeFailure(error, data: data)
        }
    }
}
