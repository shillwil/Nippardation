//
//  ExerciseAPIServiceTests.swift
//  NippardationTests
//
//  Tests for ExerciseAPIService
//

import Testing
import Foundation
@testable import Nippardation

@Suite(.serialized)
struct ExerciseAPIServiceTests {

    // Note: These tests use MockURLProtocol to intercept network requests.
    // Tests are serialized and use session-scoped MockURLProtocol handlers.
    // MockAuthTokenProvider is used to provide a valid token so requests reach the network layer.

    // MARK: - Setup

    private func createService(authProvider: AuthTokenProviding = MockAuthTokenProvider()) -> (ExerciseAPIService, String) {
        let sessionID = MockURLProtocol.makeSessionID()
        MockURLProtocol.reset(sessionID: sessionID)
        return (ExerciseAPIService(session: MockURLProtocol.mockSession(sessionID: sessionID), authProvider: authProvider), sessionID)
    }

    // MARK: - fetchExercises Tests

    @Test func fetchExercisesBuildsCorrectURL() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            // Verify URL structure
            #expect(request.url?.path.contains("api/exercises") == true)
            #expect(request.httpMethod == "GET")

            // Check query parameters
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems ?? []

            let pageItem = queryItems.first { $0.name == "page" }
            let perPageItem = queryItems.first { $0.name == "per_page" }

            #expect(pageItem?.value == "1")
            #expect(perPageItem?.value == "20")

            // Return unauthorized since we don't have a real auth token
            return MockURLProtocol.errorResponse(
                for: request.url!,
                statusCode: 401
            )
        }

        do {
            _ = try await service.fetchExercises(filters: nil, cursor: nil, limit: 20)
            Issue.record("Expected unauthorized error")
        } catch {
            #expect(error is RepositoryError)
            if case RepositoryError.unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized error, got \(error)")
            }
        }
    }

    @Test func fetchExercisesWithFiltersAddsQueryItems() async throws {
        let (service, sessionID) = createService()
        let filters = ExerciseFilters(
            muscleGroups: ["chest"],
            equipment: ["barbell"],
            searchQuery: "bench"
        )

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems ?? []

            // Verify filter query items are present
            let muscleItems = queryItems.filter { $0.name == "muscleGroup" }
            let equipmentItems = queryItems.filter { $0.name == "equipment" }
            let searchItems = queryItems.filter { $0.name == "q" }

            #expect(muscleItems.count == 1)
            #expect(muscleItems.first?.value == "chest")
            #expect(equipmentItems.count == 1)
            #expect(equipmentItems.first?.value == "barbell")
            #expect(searchItems.count == 1)
            #expect(searchItems.first?.value == "bench")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchExercises(filters: filters, cursor: nil, limit: 20)
        } catch {
            // Expected - we're just testing URL construction
        }
    }

    @Test func fetchExercisesWithCursorSetsCorrectPage() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems ?? []
            let pageItem = queryItems.first { $0.name == "page" }

            #expect(pageItem?.value == "3")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchExercises(filters: nil, cursor: "3", limit: 20)
        } catch {
            // Expected
        }
    }

    // MARK: - fetchExercise Tests

    @Test func fetchExerciseBuildsCorrectURL() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/exercises/ex_001") == true)
            #expect(request.httpMethod == "GET")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchExercise(id: "ex_001")
        } catch {
            // Expected
        }
    }

    // MARK: - fetchFilterOptions Tests

    @Test func fetchFilterOptionsBuildsCorrectURL() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/exercises/filters") == true)
            #expect(request.httpMethod == "GET")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchFilterOptions()
        } catch {
            // Expected
        }
    }

    // MARK: - recordUsage Tests

    @Test func recordUsageBuildsCorrectURL() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/exercises/ex_001/usage") == true)
            #expect(request.httpMethod == "POST")

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            try await service.recordUsage(exerciseId: "ex_001")
        } catch {
            // Expected
        }
    }

    // MARK: - Error Handling Tests

    @Test func handlesUnauthorizedError() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchExercises(filters: nil, cursor: nil, limit: 20)
            Issue.record("Expected error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    @Test func requestIncludesAuthorizationHeader() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            // Verify auth header is set with the mock token
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer mock-test-token")
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 200)
        }

        do {
            _ = try await service.fetchExercise(id: "ex_001")
        } catch {
            // May fail due to decoding, but we verified the header
        }
    }

    @Test func requestIncludesContentTypeHeader() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            // Verify Content-Type header
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 200)
        }

        do {
            try await service.recordUsage(exerciseId: "ex_001")
        } catch {
            // May fail, but we verified the header
        }
    }

    @Test func throwsUnauthorizedWhenNoToken() async throws {
        let noTokenProvider = MockAuthTokenProvider(token: nil)
        let (service, _) = createService(authProvider: noTokenProvider)

        do {
            _ = try await service.fetchExercises(filters: nil, cursor: nil, limit: 20)
            Issue.record("Expected unauthorized error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected - no token means unauthorized
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    // MARK: - Dual Format Decoding Tests

    @Test func exerciseDTODecodesPopularityScoreAsDouble() throws {
        let json = """
        {
            "id": "ex_001",
            "name": "Bench Press",
            "primaryMuscles": ["chest"],
            "popularityScore": 95.5
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder.apiDecoder.decode(ExerciseDTO.self, from: json)
        #expect(dto.popularityScore == 95.5)
    }

    @Test func exerciseDTODecodesLegacyMuscleGroupsField() throws {
        let json = """
        {
            "id": "ex_001",
            "name": "Bench Press",
            "muscleGroups": ["chest", "triceps"],
            "isCustom": false,
            "createdBy": "admin"
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder.apiDecoder.decode(ExerciseDTO.self, from: json)
        #expect(dto.primaryMuscles == nil)
        #expect(dto.muscleGroups == ["chest", "triceps"])
        #expect(dto.isCustom == false)
        #expect(dto.createdBy == "admin")
    }

    @Test func exerciseDTODecodesPrimaryMusclesAsOptional() throws {
        let json = """
        {
            "id": "ex_001",
            "name": "Bench Press"
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder.apiDecoder.decode(ExerciseDTO.self, from: json)
        #expect(dto.primaryMuscles == nil)
    }

    @Test func newFormatResponseDecodesCorrectly() throws {
        // Server returns camelCase keys for all fields
        let json = """
        {
            "success": true,
            "data": {
                "exercises": [
                    {"id": "ex_001", "name": "Bench Press", "primaryMuscles": ["chest"]}
                ],
                "pagination": {
                    "nextCursor": "abc123",
                    "hasMore": true,
                    "page": 1,
                    "perPage": 20,
                    "total": 100,
                    "totalPages": 5
                },
                "meta": {
                    "searchApplied": true,
                    "filtersApplied": ["muscleGroup"]
                }
            },
            "correlationId": "corr-123"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.apiDecoder.decode(ExerciseAPIResponse.self, from: json)
        #expect(response.success == true)
        #expect(response.data.exercises.count == 1)
        #expect(response.data.exercises[0].name == "Bench Press")
        #expect(response.data.pagination.nextCursor == "abc123")
        #expect(response.data.pagination.hasMore == true)
        #expect(response.data.meta?.searchApplied == true)
        #expect(response.correlationId == "corr-123")
    }

    @Test func legacyFormatResponseDecodesCorrectly() throws {
        let json = """
        {
            "success": true,
            "data": [
                {"id": "ex_001", "name": "Bench Press", "muscleGroups": ["chest"]}
            ],
            "pagination": {
                "page": 1,
                "perPage": 20,
                "total": 50,
                "totalPages": 3
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.apiDecoder.decode(ExerciseLegacyResponse.self, from: json)
        #expect(response.success == true)
        #expect(response.data.count == 1)
        #expect(response.data[0].muscleGroups == ["chest"])
        #expect(response.pagination.page == 1)
        #expect(response.pagination.totalPages == 3)
    }
}
