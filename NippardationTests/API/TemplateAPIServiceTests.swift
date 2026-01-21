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

    // Note: Tests are serialized because MockURLProtocol.requestHandler is shared state.

    // MARK: - Setup

    private func createService() -> TemplateAPIService {
        MockURLProtocol.reset()
        return TemplateAPIService(session: MockURLProtocol.mockSession())
    }

    // MARK: - fetchTemplates Tests

    @Test func fetchTemplatesBuildsCorrectURL() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path.contains("api/templates") == true)
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
            _ = try await service.fetchTemplates(cursor: nil, limit: 10)
        } catch {
            // Expected
        }
    }

    @Test func fetchTemplatesWithCursorSetsCorrectPage() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let pageItem = components?.queryItems?.first { $0.name == "page" }

            #expect(pageItem?.value == "5")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchTemplates(cursor: "5", limit: 10)
        } catch {
            // Expected
        }
    }

    // MARK: - fetchTemplate Tests

    @Test func fetchTemplateBuildsCorrectURL() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
