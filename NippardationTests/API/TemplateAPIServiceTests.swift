//
//  TemplateAPIServiceTests.swift
//  NippardationTests
//
//  Tests for TemplateAPIService
//

import Testing
import Foundation
@testable import Nippardation

@Suite(.serialized)
struct TemplateAPIServiceTests {

    // Note: Tests are serialized and use session-scoped MockURLProtocol handlers.
    // MockAuthTokenProvider is used to provide a valid token so requests reach the network layer.

    // MARK: - Setup

    private func createService(authProvider: AuthTokenProviding = MockAuthTokenProvider()) -> (TemplateAPIService, String) {
        let sessionID = MockURLProtocol.makeSessionID()
        MockURLProtocol.reset(sessionID: sessionID)
        return (TemplateAPIService(session: MockURLProtocol.mockSession(sessionID: sessionID), authProvider: authProvider), sessionID)
    }

    // MARK: - fetchTemplates Tests

    @Test func fetchTemplatesBuildsCorrectURL() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/templates") == true)
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
            _ = try await service.fetchTemplates(cursor: nil, limit: 10)
        } catch {
            // Expected
        }
    }

    @Test func fetchTemplatesDecodesWrappedResponse() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = """
            {"success":true,"data":{"templates":[],"pagination":{"nextCursor":null,"hasMore":false}},"correlationId":"req_test"}
            """
            return (response, body.data(using: .utf8))
        }

        let result = try await service.fetchTemplates(cursor: nil, limit: 10)
        #expect(result.templates.isEmpty)
        #expect(result.pagination.hasMore == false)
        #expect(result.pagination.nextCursor == nil)
    }

    @Test func fetchTemplatesWithCursorSetsCorrectParam() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let cursorItem = components?.queryItems?.first { $0.name == "cursor" }

            #expect(cursorItem?.value == "abc123")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchTemplates(cursor: "abc123", limit: 10)
        } catch {
            // Expected
        }
    }

    @Test func fetchTemplatesDecodesListWithExerciseCount() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = """
            {"success":true,"data":{"templates":[{"id":"tmpl_1","name":"Upper Body","exerciseCount":7,"isPublic":false,"createdAt":"2026-02-20T10:00:00.000Z","updatedAt":"2026-02-20T10:00:00.000Z"}],"pagination":{"nextCursor":null,"hasMore":false}},"correlationId":"req_test"}
            """
            return (response, body.data(using: .utf8))
        }

        let result = try await service.fetchTemplates(cursor: nil, limit: 10)
        #expect(result.templates.count == 1)
        #expect(result.templates[0].id == "tmpl_1")
        #expect(result.templates[0].name == "Upper Body")
        #expect(result.pagination.hasMore == false)
    }

    // MARK: - fetchTemplate Tests

    @Test func fetchTemplateBuildsCorrectURL() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/templates/tmpl_001") == true)
            #expect(request.httpMethod == "GET")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchTemplate(id: "tmpl_001")
        } catch {
            // Expected
        }
    }

    // MARK: - createTemplate Tests

    @Test func createTemplateBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/templates") == true)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            // Verify body contains expected data
            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                #expect(json["name"] as? String == "New Template")
            }

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let createRequest = CreateTemplateRequest(
            name: "New Template",
            description: "Test description",
            exercises: [],
            isPublic: false
        )

        do {
            _ = try await service.createTemplate(createRequest)
        } catch {
            // Expected
        }
    }

    // MARK: - updateTemplate Tests

    @Test func updateTemplateBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/templates/tmpl_001") == true)
            #expect(request.httpMethod == "PUT")

            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                #expect(json["name"] as? String == "Updated Name")
            }

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let updateRequest = UpdateTemplateRequest(name: "Updated Name", description: nil)

        do {
            _ = try await service.updateTemplate(id: "tmpl_001", updateRequest)
        } catch {
            // Expected
        }
    }

    // MARK: - updateTemplateExercises Tests

    @Test func updateTemplateExercisesBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/templates/tmpl_001/exercises") == true)
            #expect(request.httpMethod == "PUT")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let exercises = [
            TemplateExerciseInput(
                exerciseId: "ex_001",
                orderIndex: 0,
                warmupSets: 2,
                workingSets: 3,
                targetReps: "8-12",
                restSeconds: 90,
                notes: nil
            )
        ]

        do {
            _ = try await service.updateTemplateExercises(id: "tmpl_001", exercises)
        } catch {
            // Expected
        }
    }

    // MARK: - cloneTemplate Tests

    @Test func cloneTemplateBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/templates/tmpl_001/clone") == true)
            #expect(request.httpMethod == "POST")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.cloneTemplate(id: "tmpl_001", newName: "Cloned Template")
        } catch {
            // Expected
        }
    }

    @Test func cloneTemplateWithoutNameOmitsBody() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/templates/tmpl_001/clone") == true)
            // When no name provided, body should be nil or empty
            #expect(request.httpBody == nil || request.httpBody?.isEmpty == true)

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.cloneTemplate(id: "tmpl_001", newName: nil)
        } catch {
            // Expected
        }
    }

    // MARK: - deleteTemplate Tests

    @Test func deleteTemplateBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/templates/tmpl_001") == true)
            #expect(request.httpMethod == "DELETE")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            try await service.deleteTemplate(id: "tmpl_001")
        } catch {
            // Expected
        }
    }

    // Note: deleteTemplateHandles409Conflict cannot be tested without mocking AuthManager,
    // since the auth check happens before the network request reaches the mock layer.

    // MARK: - Error Handling Tests
    //
    // Note: Tests for network-level errors (timeout, connection lost) and HTTP status codes
    // (404, 409) cannot be tested without mocking AuthManager, since the auth check happens
    // before the network request. The following tests verify auth-related behavior.

    @Test func handlesUnauthorized() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchTemplates(cursor: nil, limit: 10)
            Issue.record("Expected error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    @Test func fetchTemplateRequiresAuth() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchTemplate(id: "tmpl_001")
            Issue.record("Expected error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    @Test func createTemplateRequiresAuth() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let createRequest = CreateTemplateRequest(
            name: "Test Template",
            description: "Description",
            exercises: [],
            isPublic: false
        )

        do {
            _ = try await service.createTemplate(createRequest)
            Issue.record("Expected error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    @Test func deleteTemplateRequiresAuth() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            try await service.deleteTemplate(id: "tmpl_001")
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
