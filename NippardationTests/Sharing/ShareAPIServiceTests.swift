//
//  ShareAPIServiceTests.swift
//  NippardationTests
//
//  Tests for ShareAPIService
//

import Testing
import Foundation
@testable import Nippardation

@Suite(.serialized)
struct ShareAPIServiceTests {

    private func createService(authProvider: AuthTokenProviding = MockAuthTokenProvider()) -> (ShareAPIService, String) {
        let sessionID = MockURLProtocol.makeSessionID()
        MockURLProtocol.reset(sessionID: sessionID)
        return (ShareAPIService(session: MockURLProtocol.mockSession(sessionID: sessionID), authProvider: authProvider), sessionID)
    }

    // MARK: - createShare Tests

    @Test func createShareBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/shares") == true)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                #expect(json["type"] as? String == "program")
                #expect(json["itemId"] as? String == "prog_001")
            }

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.createShare(type: "program", itemId: "prog_001")
        } catch {
            // Expected — we returned 401
        }
    }

    @Test func createShareDecodesWrappedResponse() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let json: [String: Any] = [
                "success": true,
                "data": [
                    "token": "abc123",
                    "shareUrl": "nippardation://share/abc123",
                    "expiresAt": NSNull()
                ]
            ]
            let data = try! JSONSerialization.data(withJSONObject: json)
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let result = try await service.createShare(type: "program", itemId: "prog_001")
        #expect(result.token == "abc123")
        #expect(result.shareUrl == "nippardation://share/abc123")
        #expect(result.expiresAt == nil)
    }

    @Test func createShareDecodesFlatResponse() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let json: [String: Any] = [
                "token": "def456",
                "shareUrl": "nippardation://share/def456",
                "expiresAt": NSNull()
            ]
            let data = try! JSONSerialization.data(withJSONObject: json)
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let result = try await service.createShare(type: "template", itemId: "tmpl_001")
        #expect(result.token == "def456")
    }

    @Test func createShareRequiresAuth() async throws {
        let (service, sessionID) = createService(authProvider: MockAuthTokenProvider(token: nil))

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 200)
        }

        do {
            _ = try await service.createShare(type: "program", itemId: "prog_001")
            Issue.record("Expected unauthorized error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    // MARK: - fetchShare Tests

    @Test func fetchShareBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/shares/test_token") == true)
            #expect(request.httpMethod == "GET")
            // fetchShare does NOT require auth
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 404)
        }

        do {
            _ = try await service.fetchShare(token: "test_token")
        } catch {
            // Expected
        }
    }

    @Test func fetchShareDecodesWrappedResponse() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let json: [String: Any] = [
                "success": true,
                "data": [
                    "token": "abc123",
                    "type": "template",
                    "sharedBy": [
                        "handle": "testuser",
                        "displayName": "Test User"
                    ],
                    "sharedAt": "2026-03-08T12:00:00Z",
                    "expiresAt": NSNull(),
                    "template": [
                        "id": "tmpl_001",
                        "name": "Push Day",
                        "exercises": [] as [[String: Any]],
                        "isPublic": false,
                        "createdAt": "2026-01-01T00:00:00Z",
                        "updatedAt": "2026-01-01T00:00:00Z"
                    ] as [String: Any]
                ] as [String: Any]
            ]
            let data = try! JSONSerialization.data(withJSONObject: json)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let result = try await service.fetchShare(token: "abc123")
        #expect(result.type == "template")
        #expect(result.sharedBy.handle == "testuser")
        #expect(result.sharedBy.displayName == "Test User")
        #expect(result.template?.name == "Push Day")
        #expect(result.program == nil)
    }

    @Test func fetchShareHandles404() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 404)
        }

        do {
            _ = try await service.fetchShare(token: "invalid_token")
            Issue.record("Expected notFound error")
        } catch let error as RepositoryError {
            if case .notFound = error {
                // Expected
            } else {
                Issue.record("Expected notFound, got \(error)")
            }
        }
    }
}
