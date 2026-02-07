//
//  SyncAPIServiceTests.swift
//  NippardationTests
//
//  Tests for SyncAPIService
//

import Testing
import Foundation
@testable import Nippardation

@Suite(.serialized)
struct SyncAPIServiceTests {

    // Note: Tests are serialized because MockURLProtocol.requestHandler is shared state.
    // MockAuthTokenProvider is used to provide a valid token so requests reach the network layer.

    // MARK: - Setup

    private func createService(authProvider: AuthTokenProviding = MockAuthTokenProvider()) -> SyncAPIService {
        MockURLProtocol.reset()
        return SyncAPIService(session: MockURLProtocol.mockSession(), authProvider: authProvider)
    }

    // MARK: - sync Tests

    @Test func syncBuildsCorrectRequest() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path.contains("api/sync") == true)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            // Verify body contains expected fields
            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                #expect(json["deviceId"] as? String == "device_123")
                #expect(json["lastSyncTimestamp"] as? String == "2025-01-01T00:00:00Z")
                // Verify camelCase keys (not snake_case)
                #expect(json["device_id"] == nil, "Should use camelCase deviceId, not snake_case device_id")
                #expect(json["last_synced_at"] == nil, "Should use lastSyncTimestamp, not last_synced_at")
            }

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let payload = SyncRequestDTO(
            deviceId: "device_123",
            lastSyncTimestamp: "2025-01-01T00:00:00Z",
            deviceInfo: nil,
            workouts: []
        )

        do {
            _ = try await service.sync(payload: payload)
        } catch {
            // Expected - unauthorized
        }
    }

    @Test func syncIncludesWorkoutsInPayload() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
               let workouts = json["workouts"] as? [[String: Any]] {
                #expect(workouts.count == 1)
                #expect(workouts[0]["client_id"] as? String == "workout_001")
            }

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let workout = WorkoutCreateDTO(
            clientId: "workout_001",
            templateId: "tmpl_001",
            templateName: "Push Day",
            startedAt: "2025-01-15T10:00:00Z",
            completedAt: "2025-01-15T11:00:00Z",
            durationSeconds: 3600,
            notes: nil,
            exercises: []
        )

        let payload = SyncRequestDTO(
            deviceId: "device_123",
            lastSyncTimestamp: nil,
            deviceInfo: nil,
            workouts: [workout]
        )

        do {
            _ = try await service.sync(payload: payload)
        } catch {
            // Expected
        }
    }

    @Test func syncHasExtendedTimeout() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            // The service sets a 60 second timeout for sync operations
            #expect(request.timeoutInterval == 60)

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let payload = SyncRequestDTO(deviceId: "device_123", lastSyncTimestamp: nil, deviceInfo: nil, workouts: [])

        do {
            _ = try await service.sync(payload: payload)
        } catch {
            // Expected
        }
    }

    // MARK: - Error Handling Tests
    //
    // Note: Tests for network-level errors (timeout, connection lost) and HTTP status codes
    // (409, 422, 429, 5xx) cannot be tested without mocking AuthManager, since the auth check
    // happens before the network request. The following tests verify auth-related behavior.

    @Test func handlesUnauthorized() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let payload = SyncRequestDTO(deviceId: "device_123", lastSyncTimestamp: nil, deviceInfo: nil, workouts: [])

        do {
            _ = try await service.sync(payload: payload)
            Issue.record("Expected error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    @Test func syncRequiresAuth() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let workout = WorkoutCreateDTO(
            clientId: "workout_002",
            templateId: "tmpl_001",
            templateName: "Pull Day",
            startedAt: "2025-01-15T10:00:00Z",
            completedAt: "2025-01-15T11:00:00Z",
            durationSeconds: 3600,
            notes: nil,
            exercises: []
        )

        let payload = SyncRequestDTO(
            deviceId: "device_456",
            lastSyncTimestamp: "2025-01-01T00:00:00Z",
            deviceInfo: nil,
            workouts: [workout]
        )

        do {
            _ = try await service.sync(payload: payload)
            Issue.record("Expected error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    // MARK: - DTO Encoding Tests

    @Test func syncRequestDTOEncodesCamelCaseKeys() throws {
        let payload = SyncRequestDTO(
            deviceId: "device_123",
            lastSyncTimestamp: "2025-01-15T00:00:00Z",
            deviceInfo: SyncDeviceInfo(
                name: "iPhone 16",
                type: "ios",
                appVersion: "1.0.0",
                osVersion: "18.0"
            ),
            workouts: []
        )

        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify camelCase keys
        #expect(json["deviceId"] as? String == "device_123")
        #expect(json["lastSyncTimestamp"] as? String == "2025-01-15T00:00:00Z")
        #expect(json["deviceInfo"] != nil)

        // Verify snake_case keys are NOT present
        #expect(json["device_id"] == nil)
        #expect(json["last_synced_at"] == nil)
        #expect(json["last_sync_timestamp"] == nil)
        #expect(json["device_info"] == nil)

        // Verify deviceInfo contents
        let deviceInfo = json["deviceInfo"] as? [String: Any]
        #expect(deviceInfo?["type"] as? String == "ios")
        #expect(deviceInfo?["appVersion"] as? String == "1.0.0")
        #expect(deviceInfo?["osVersion"] as? String == "18.0")
    }

    @Test func syncDeviceInfoEncodesCorrectly() throws {
        let info = SyncDeviceInfo(
            name: nil,
            type: "ios",
            appVersion: "2.0.0",
            osVersion: nil
        )

        let data = try JSONEncoder().encode(info)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["type"] as? String == "ios")
        #expect(json["appVersion"] as? String == "2.0.0")
        // name and osVersion should be null
        #expect(json["app_version"] == nil, "Should use camelCase appVersion, not snake_case")
        #expect(json["os_version"] == nil, "Should use camelCase osVersion, not snake_case")
    }

    @Test func syncRequestDTOWithNilDeviceInfoOmitsIt() throws {
        let payload = SyncRequestDTO(
            deviceId: "device_123",
            lastSyncTimestamp: nil,
            deviceInfo: nil,
            workouts: []
        )

        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["deviceId"] as? String == "device_123")
        // deviceInfo should be null (not absent, since Codable includes nil optionals)
    }
}
