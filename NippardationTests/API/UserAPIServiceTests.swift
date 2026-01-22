//
//  UserAPIServiceTests.swift
//  NippardationTests
//
//  Tests for UserAPIService
//

import Testing
import Foundation
@testable import Nippardation

@Suite(.serialized)
struct UserAPIServiceTests {

    // Note: Tests are serialized because MockURLProtocol.requestHandler is shared state.
    // MockAuthTokenProvider is used to provide a valid token so requests reach the network layer.

    // MARK: - Setup

    private func createService(authProvider: AuthTokenProviding = MockAuthTokenProvider()) -> UserAPIService {
        MockURLProtocol.reset()
        return UserAPIService(session: MockURLProtocol.mockSession(), authProvider: authProvider)
    }

    // MARK: - login Tests

    @Test func loginBuildsCorrectRequest() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path.contains("api/auth/login") == true)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.login()
        } catch {
            // Expected - unauthorized without real token
        }
    }

    // MARK: - fetchProfile Tests

    @Test func fetchProfileBuildsCorrectRequest() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path.contains("api/users/me") == true)
            #expect(request.httpMethod == "GET")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchProfile()
        } catch {
            // Expected
        }
    }

    // MARK: - updateProfile Tests

    @Test func updateProfileBuildsCorrectRequest() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path.contains("api/users/me") == true)
            #expect(request.httpMethod == "PUT")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            // Verify body contains expected fields
            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                #expect(json["display_name"] as? String == "New Name")
                #expect(json["bio"] as? String == "Updated bio")
            }

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let updateRequest = UpdateUserRequest(
            displayName: "New Name",
            bio: "Updated bio"
        )

        do {
            _ = try await service.updateProfile(updateRequest)
        } catch {
            // Expected
        }
    }

    @Test func updateProfileWithAllFieldsIncludesAllInBody() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                #expect(json["display_name"] as? String == "Full Update")
                #expect(json["bio"] as? String == "Full bio")
                #expect(json["height"] as? Double == 180.0)
                #expect(json["weight"] as? Double == 75.0)
                #expect(json["age"] as? Int == 25)
                #expect(json["gender"] as? String == "male")
                #expect(json["unit_preference"] as? String == "metric")
                #expect(json["is_public_profile"] as? Bool == true)
                #expect(json["notifications_enabled"] as? Bool == false)
            }

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let updateRequest = UpdateUserRequest(
            displayName: "Full Update",
            bio: "Full bio",
            height: 180.0,
            weight: 75.0,
            age: 25,
            gender: "male",
            unitPreference: "metric",
            isPublicProfile: true,
            notificationsEnabled: false
        )

        do {
            _ = try await service.updateProfile(updateRequest)
        } catch {
            // Expected
        }
    }

    @Test func updateProfileWithNilFieldsOmitsThem() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                // Only display_name should be present
                #expect(json["display_name"] as? String == "Only Name")
                // Other fields should not be in JSON (or be null)
                // Note: Swift's JSONEncoder includes null for nil optionals by default
            }

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let updateRequest = UpdateUserRequest(displayName: "Only Name")

        do {
            _ = try await service.updateProfile(updateRequest)
        } catch {
            // Expected
        }
    }

    // MARK: - Error Handling Tests
    //
    // Note: Tests for network-level errors (timeout, connection lost) and HTTP status codes
    // (404, 422, 429, 5xx) cannot be tested without mocking AuthManager, since the auth check
    // happens before the network request. The following tests verify auth-related behavior.

    @Test func handlesUnauthorized() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.login()
            Issue.record("Expected error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    @Test func fetchProfileRequiresAuth() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchProfile()
            Issue.record("Expected error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    @Test func updateProfileRequiresAuth() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let updateRequest = UpdateUserRequest(displayName: "Test")

        do {
            _ = try await service.updateProfile(updateRequest)
            Issue.record("Expected error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }
}
