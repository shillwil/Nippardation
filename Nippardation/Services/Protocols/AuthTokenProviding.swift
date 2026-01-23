//
//  AuthTokenProviding.swift
//  Nippardation
//
//  Protocol for providing auth tokens, enabling dependency injection for testing
//

import Foundation

/// Protocol for providing authentication tokens
/// Enables dependency injection of auth in API services for testability
protocol AuthTokenProviding: Sendable {
    func getIDToken() async throws -> String?
}

/// Default implementation that uses AuthManager
final class DefaultAuthTokenProvider: AuthTokenProviding, @unchecked Sendable {
    static let shared = DefaultAuthTokenProvider()

    private init() {}

    func getIDToken() async throws -> String? {
        try await AuthManager.shared.getIDToken()
    }
}
