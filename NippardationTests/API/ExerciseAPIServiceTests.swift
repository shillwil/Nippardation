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
    // Tests are serialized because MockURLProtocol.requestHandler is shared state.
    // MockAuthTokenProvider is used to provide a valid token so requests reach the network layer.

    // MARK: - Setup

    private func createService(authProvider: AuthTokenProviding = MockAuthTokenProvider()) -> ExerciseAPIService {
        MockURLProtocol.reset()
        return ExerciseAPIService(session: MockURLProtocol.mockSession(), authProvider: authProvider)
    }

    // MARK: - fetchExercises Tests

    @Test func fetchExercisesBuildsCorrectURL() async throws {
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()
        let filters = ExerciseFilters(
            muscleGroups: ["chest"],
            equipment: ["barbell"],
            searchQuery: "bench"
        )

        MockURLProtocol.requestHandler = { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems ?? []

            // Verify filter query items are present
            let muscleItems = queryItems.filter { $0.name == "muscle_groups[]" }
            let equipmentItems = queryItems.filter { $0.name == "equipment[]" }
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService()

        MockURLProtocol.requestHandler = { request in
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
        let service = createService(authProvider: noTokenProvider)

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
}
