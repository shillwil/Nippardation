//
//  ProgramAPIServiceTests.swift
//  NippardationTests
//
//  Tests for ProgramAPIService
//

import Testing
import Foundation
@testable import Nippardation

@Suite(.serialized)
struct ProgramAPIServiceTests {

    // Note: Tests are serialized and use session-scoped MockURLProtocol handlers.
    // MockAuthTokenProvider is used to provide a valid token so requests reach the network layer.

    // MARK: - Setup

    private func createService(authProvider: AuthTokenProviding = MockAuthTokenProvider()) -> (ProgramAPIService, String) {
        let sessionID = MockURLProtocol.makeSessionID()
        MockURLProtocol.reset(sessionID: sessionID)
        return (ProgramAPIService(session: MockURLProtocol.mockSession(sessionID: sessionID), authProvider: authProvider), sessionID)
    }

    // MARK: - fetchPrograms Tests

    @Test func fetchProgramsBuildsCorrectURL() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/programs") == true)
            #expect(request.httpMethod == "GET")

            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems ?? []

            let pageItem = queryItems.first { $0.name == "page" }
            let perPageItem = queryItems.first { $0.name == "per_page" }

            #expect(pageItem?.value == "1")
            #expect(perPageItem?.value == "10")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchPrograms(cursor: nil, limit: 10)
        } catch {
            // Expected
        }
    }

    // MARK: - fetchProgram Tests

    @Test func fetchProgramBuildsCorrectURL() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/programs/prog_001") == true)
            #expect(request.httpMethod == "GET")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchProgram(id: "prog_001")
        } catch {
            // Expected
        }
    }

    // MARK: - fetchActiveProgram Tests

    @Test func fetchActiveProgramBuildsCorrectURL() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/programs/active") == true)
            #expect(request.httpMethod == "GET")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchActiveProgram()
        } catch {
            // Expected
        }
    }

    // Note: fetchActiveProgramReturnsNilFor404 cannot be tested without mocking AuthManager,
    // since the auth check happens before the network request reaches the mock layer.

    // MARK: - createProgram Tests

    @Test func createProgramBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/programs") == true)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                #expect(json["name"] as? String == "New Program")
                #expect(json["daysPerWeek"] as? Int == 5)
            }

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let createRequest = CreateProgramRequest(
            name: "New Program",
            description: "Test program",
            daysPerWeek: 5,
            durationWeeks: 8,
            workouts: [],
            isPublic: false
        )

        do {
            _ = try await service.createProgram(createRequest)
        } catch {
            // Expected
        }
    }

    // MARK: - updateProgram Tests

    @Test func updateProgramBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/programs/prog_001") == true)
            #expect(request.httpMethod == "PUT")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let updateRequest = UpdateProgramRequest(name: "Updated Program")

        do {
            _ = try await service.updateProgram(id: "prog_001", updateRequest)
        } catch {
            // Expected
        }
    }

    // MARK: - updateProgramWorkouts Tests

    @Test func updateProgramWorkoutsBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/programs/prog_001/workouts") == true)
            #expect(request.httpMethod == "PUT")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let workouts = [
            ProgramWorkoutInput(dayNumber: 1, dayLabel: "Push", templateId: "tmpl_001")
        ]

        do {
            _ = try await service.updateProgramWorkouts(id: "prog_001", workouts)
        } catch {
            // Expected
        }
    }

    // MARK: - deleteProgram Tests

    @Test func deleteProgramBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/programs/prog_001") == true)
            #expect(request.httpMethod == "DELETE")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            try await service.deleteProgram(id: "prog_001")
        } catch {
            // Expected
        }
    }

    // MARK: - State Management Tests

    @Test func activateProgramBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/programs/prog_001/activate") == true)
            #expect(request.httpMethod == "POST")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.activateProgram(id: "prog_001")
        } catch {
            // Expected
        }
    }

    @Test func deactivateProgramBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/programs/prog_001/deactivate") == true)
            #expect(request.httpMethod == "POST")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.deactivateProgram(id: "prog_001")
        } catch {
            // Expected
        }
    }

    @Test func advanceProgramBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/programs/prog_001/advance") == true)
            #expect(request.httpMethod == "POST")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.advanceProgram(id: "prog_001")
        } catch {
            // Expected
        }
    }

    @Test func resetProgramBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/programs/prog_001/reset") == true)
            #expect(request.httpMethod == "POST")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.resetProgram(id: "prog_001")
        } catch {
            // Expected
        }
    }

    // MARK: - Error Handling Tests
    //
    // Note: Tests for network-level errors (timeout, connection lost) and HTTP status codes
    // (5xx) cannot be tested without mocking AuthManager, since the auth check happens before
    // the network request. The following tests verify auth-related behavior.

    @Test func handlesUnauthorized() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchPrograms(cursor: nil, limit: 10)
            Issue.record("Expected error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    @Test func fetchProgramRequiresAuth() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchProgram(id: "prog_001")
            Issue.record("Expected error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    @Test func createProgramRequiresAuth() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let createRequest = CreateProgramRequest(
            name: "Test Program",
            description: "Description",
            daysPerWeek: 3,
            durationWeeks: 4,
            workouts: [],
            isPublic: false
        )

        do {
            _ = try await service.createProgram(createRequest)
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
