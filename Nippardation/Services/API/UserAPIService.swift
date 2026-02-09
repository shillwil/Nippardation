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

final class UserAPIService: BaseAPIService, UserAPIServiceProtocol, @unchecked Sendable {

    override init(session: URLSession = .shared, authProvider: AuthTokenProviding = DefaultAuthTokenProvider.shared) {
        super.init(session: session, authProvider: authProvider)
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
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/me")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: UserResponse = try await performRequest(request)
        return response.user
    }

    func updateProfile(_ updateRequest: UpdateUserRequest) async throws -> UserDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/me")

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(updateRequest)
        try await addAuthHeader(to: &request)

        let response: UserResponse = try await performRequest(request)
        return response.user
    }

}
