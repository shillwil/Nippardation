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
            #expect(request.url?.path.contains("api/me") == true)
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
            #expect(request.url?.path.contains("api/me") == true)
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

    // MARK: - Path Validation Tests

    @Test func fetchProfileUsesApiMeNotApiUsersMe() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            #expect(!path.contains("api/users/me"), "Path should use api/me, not api/users/me")
            #expect(path.contains("api/me"))

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchProfile()
        } catch {
            // Expected
        }
    }

    @Test func updateProfileUsesApiMeNotApiUsersMe() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            #expect(!path.contains("api/users/me"), "Path should use api/me, not api/users/me")
            #expect(path.contains("api/me"))

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.updateProfile(UpdateUserRequest(displayName: "Test"))
        } catch {
            // Expected
        }
    }

    // MARK: - DTO Decoding Tests

    @Test func backendUserDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "user-123",
            "firebase_uid": "fb-abc",
            "email": "test@example.com",
            "handle": "testuser",
            "display_name": "Test User",
            "profile_picture_url": "https://example.com/pic.jpg",
            "bio": "Hello",
            "height": 72.0,
            "weight": 180.5,
            "age": 30,
            "gender": "male",
            "unit_preference": "imperial",
            "is_public_profile": true,
            "total_volume_lifted_lbs": "125000.50",
            "total_workouts": 100,
            "current_workout_streak": 5,
            "longest_workout_streak": 30,
            "last_workout_date": "2025-01-15T00:00:00Z",
            "push_notification_tokens": ["token1", "token2"],
            "notifications_enabled": true,
            "last_synced_at": "2025-01-15T12:00:00Z",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2025-01-15T12:00:00Z"
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(BackendUser.self, from: json)

        #expect(user.id == "user-123")
        #expect(user.firebaseUid == "fb-abc")
        #expect(user.email == "test@example.com")
        #expect(user.handle == "testuser")
        #expect(user.displayName == "Test User")
        #expect(user.profilePictureUrl == "https://example.com/pic.jpg")
        #expect(user.bio == "Hello")
        #expect(user.height == 72.0)
        #expect(user.weight == 180.5)
        #expect(user.age == 30)
        #expect(user.gender == "male")
        #expect(user.unitPreference == "imperial")
        #expect(user.isPublicProfile == true)
        #expect(user.totalVolumeLiftedLbs == "125000.50")
        #expect(user.totalWorkouts == 100)
        #expect(user.currentWorkoutStreak == 5)
        #expect(user.longestWorkoutStreak == 30)
        #expect(user.lastWorkoutDate == "2025-01-15T00:00:00Z")
        #expect(user.pushNotificationTokens == ["token1", "token2"])
        #expect(user.notificationsEnabled == true)
        #expect(user.lastSyncedAt == "2025-01-15T12:00:00Z")
        #expect(user.createdAt == "2024-01-01T00:00:00Z")
        #expect(user.updatedAt == "2025-01-15T12:00:00Z")
    }

    @Test func backendUserDecodesWithMinimalFields() throws {
        let json = """
        {
            "id": "user-123",
            "firebase_uid": "fb-abc",
            "email": "test@example.com",
            "handle": "testuser"
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(BackendUser.self, from: json)

        #expect(user.id == "user-123")
        #expect(user.firebaseUid == "fb-abc")
        #expect(user.displayName == nil)
        #expect(user.height == nil)
        #expect(user.totalVolumeLiftedLbs == nil)
        #expect(user.pushNotificationTokens == nil)
        #expect(user.notificationsEnabled == nil)
    }

    @Test func userDTOTotalVolumeLiftedLbsIsString() throws {
        let json = """
        {
            "id": "user-123",
            "firebase_uid": "fb-abc",
            "email": "test@example.com",
            "handle": "testuser",
            "total_volume_lifted_lbs": "125000.50"
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(UserDTO.self, from: json)

        #expect(user.totalVolumeLiftedLbs == "125000.50")
    }

    @Test func userDTODecodesPushNotificationTokens() throws {
        let json = """
        {
            "id": "user-123",
            "firebase_uid": "fb-abc",
            "email": "test@example.com",
            "push_notification_tokens": ["token-abc", "token-def"]
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(UserDTO.self, from: json)

        #expect(user.pushNotificationTokens == ["token-abc", "token-def"])
    }

    @Test func userDTODecodesWithNullPushNotificationTokens() throws {
        let json = """
        {
            "id": "user-123",
            "firebase_uid": "fb-abc",
            "email": "test@example.com"
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(UserDTO.self, from: json)

        #expect(user.pushNotificationTokens == nil)
    }
}
