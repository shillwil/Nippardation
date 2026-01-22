//
//  MockAuthTokenProvider.swift
//  NippardationTests
//
//  Mock auth token provider for testing API services
//

import Foundation
@testable import Nippardation

/// Mock auth token provider for testing
/// Returns a configurable token or throws an error as specified
final class MockAuthTokenProvider: AuthTokenProviding, @unchecked Sendable {

    /// The token to return from getIDToken()
    var token: String? = "mock-test-token"

    /// Error to throw instead of returning token
    var errorToThrow: Error?

    init(token: String? = "mock-test-token") {
        self.token = token
    }

    func getIDToken() async throws -> String? {
        if let error = errorToThrow {
            throw error
        }
        return token
    }
}
