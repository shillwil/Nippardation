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

            let limitItem = queryItems.first { $0.name == "limit" }
            let cursorItem = queryItems.first { $0.name == "cursor" }

            #expect(limitItem?.value == "10")
            #expect(cursorItem == nil)

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchPrograms(cursor: nil, limit: 10)
        } catch {
            // Expected
        }
    }

    @Test func fetchProgramsDecodesWrappedResponse() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = """
            {"success":true,"data":{"programs":[],"pagination":{"nextCursor":null,"hasMore":false}},"correlationId":"req_test"}
            """
            return (response, body.data(using: .utf8))
        }

        let result = try await service.fetchPrograms(cursor: nil, limit: 10)
        #expect(result.programs.isEmpty)
        #expect(result.pagination.hasMore == false)
        #expect(result.pagination.nextCursor == nil)
    }

    @Test func fetchProgramsDecodesListWithWorkoutCount() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = """
            {"success":true,"data":{"programs":[{"id":"prog_1","name":"PPL","daysPerWeek":6,"workoutCount":6,"isActive":true,"currentDayIndex":2,"timesCompleted":0,"createdAt":"2026-02-20T10:00:00.000Z","updatedAt":"2026-02-20T10:00:00.000Z"}],"pagination":{"nextCursor":null,"hasMore":false}},"correlationId":"req_test"}
            """
            return (response, body.data(using: .utf8))
        }

        let result = try await service.fetchPrograms(cursor: nil, limit: 10)
        #expect(result.programs.count == 1)
        #expect(result.programs[0].id == "prog_1")
        #expect(result.programs[0].name == "PPL")
        #expect(result.programs[0].workouts == nil)
        #expect(result.pagination.hasMore == false)
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

    @Test func createProgramDecodesWrappedResponseWithTemplateSummary() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = """
            {"success":true,"data":{"program":{"id":"prog_123","name":"YOLO Swag","description":null,"daysPerWeek":5,"durationWeeks":null,"isActive":false,"currentDayIndex":0,"timesCompleted":0,"isPublic":false,"isAiGenerated":false,"workouts":[{"id":"w_1","dayNumber":0,"dayLabel":"Day 1","templateId":"tmpl_1","template":{"id":"tmpl_1","name":"Upper","description":null,"exerciseCount":8}}],"createdAt":"2026-02-23T17:33:13.533Z","updatedAt":"2026-02-23T17:33:13.533Z"}},"correlationId":"req_test"}
            """
            return (response, body.data(using: .utf8))
        }

        let createRequest = CreateProgramRequest(
            name: "YOLO Swag",
            description: nil,
            daysPerWeek: 5,
            durationWeeks: nil,
            workouts: [],
            isPublic: false
        )

        let dto = try await service.createProgram(createRequest)
        #expect(dto.id == "prog_123")
        #expect(dto.workouts?.count == 1)
        #expect(dto.workouts?.first?.template?.id == "tmpl_1")
        #expect(dto.workouts?.first?.template?.name == "Upper")
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
