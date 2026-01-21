//
//  UserAPIService.swift
//  Nippardation
//
//  API service for user/auth operations
//

import Foundation

/// Response wrapper for user endpoints
private struct UserResponse: Codable {
    let success: Bool
    let user: UserDTO
}

final class UserAPIService: UserAPIServiceProtocol, @unchecked Sendable {

    private let session: URLSession
    private let decoder = JSONDecoder.apiDecoder
    private let encoder = JSONEncoder.apiEncoder

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - UserAPIServiceProtocol

    func login() async throws -> UserDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/auth/login")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let response: UserResponse = try await performRequest(request)
        return response.user
    }

    func fetchProfile() async throws -> UserDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/users/me")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: UserResponse = try await performRequest(request)
        return response.user
    }

    func updateProfile(_ updateRequest: UpdateUserRequest) async throws -> UserDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/users/me")

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(updateRequest)
        try await addAuthHeader(to: &request)

        let response: UserResponse = try await performRequest(request)
        return response.user
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
