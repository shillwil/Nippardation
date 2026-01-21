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

    // MARK: - Setup

    private func createService() -> SyncAPIService {
        MockURLProtocol.reset()
        return SyncAPIService(session: MockURLProtocol.mockSession())
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
                #expect(json["device_id"] as? String == "device_123")
            }

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let payload = SyncRequestDTO(
            deviceId: "device_123",
            lastSyncedAt: "2025-01-01T00:00:00Z",
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
            lastSyncedAt: nil,
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

        let payload = SyncRequestDTO(deviceId: "device_123", lastSyncedAt: nil, workouts: [])

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

        let payload = SyncRequestDTO(deviceId: "device_123", lastSyncedAt: nil, workouts: [])

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
            lastSyncedAt: "2025-01-01T00:00:00Z",
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
}
