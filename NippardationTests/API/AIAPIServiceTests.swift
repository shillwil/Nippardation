//
//  AIAPIServiceTests.swift
//  NippardationTests
//
//  Tests for AIAPIService
//

import Testing
import Foundation
@testable import Nippardation

@Suite(.serialized)
struct AIAPIServiceTests {

    private func createService(authProvider: AuthTokenProviding = MockAuthTokenProvider()) -> (AIAPIService, String) {
        let sessionID = MockURLProtocol.makeSessionID()
        MockURLProtocol.reset(sessionID: sessionID)
        return (AIAPIService(session: MockURLProtocol.mockSession(sessionID: sessionID), authProvider: authProvider), sessionID)
    }

    // MARK: - generateProgram Tests

    @Test func generateProgramBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/ai/generate-program") == true)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                #expect(json["inspirationSource"] as? String == "Push Pull Legs")
                #expect(json["daysPerWeek"] as? Int == 4)
                #expect(json["sessionDurationMinutes"] as? Int == 60)
                #expect(json["experienceLevel"] as? String == "intermediate")
                #expect(json["goal"] as? String == "hypertrophy")
                #expect((json["equipment"] as? [String])?.count == 3)
                #expect(json["useTrainingHistory"] as? Bool == false)
            }

            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        let request = GenerateProgramRequest(
            inspirationSource: "Push Pull Legs",
            daysPerWeek: 4,
            sessionDurationMinutes: 60,
            experienceLevel: "intermediate",
            goal: "hypertrophy",
            equipment: ["barbell", "dumbbell", "cable"],
            useTrainingHistory: false,
            manualStrengthData: nil,
            freeTextPreferences: nil
        )

        do {
            _ = try await service.generateProgram(request)
        } catch {
            // Expected — we returned 401
        }
    }

    @Test func generateProgramDecodesResponse() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let json: [String: Any] = [
                "success": true,
                "data": [
                    "program": [
                        "id": "ai_prog_001",
                        "name": "AI Hypertrophy Program",
                        "description": "A 4-day program",
                        "daysPerWeek": 4,
                        "durationWeeks": 8,
                        "workouts": [] as [[String: Any]],
                        "isAiGenerated": true,
                        "createdAt": "2026-03-23T00:00:00Z",
                        "updatedAt": "2026-03-23T00:00:00Z"
                    ] as [String: Any],
                    "generation": [
                        "timeMs": 15000,
                        "model": "claude-sonnet-4-5-20250514",
                        "personalizationApplied": true
                    ] as [String: Any]
                ] as [String: Any],
                "correlationId": "req_test_123"
            ]
            let data = try! JSONSerialization.data(withJSONObject: json)
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let request = GenerateProgramRequest(
            inspirationSource: "PPL",
            daysPerWeek: 4,
            sessionDurationMinutes: 60,
            experienceLevel: "intermediate",
            goal: "hypertrophy",
            equipment: ["barbell"],
            useTrainingHistory: false,
            manualStrengthData: nil,
            freeTextPreferences: nil
        )

        let result = try await service.generateProgram(request)
        #expect(result.program.id == "ai_prog_001")
        #expect(result.program.name == "AI Hypertrophy Program")
        #expect(result.program.isAiGenerated == true)
        #expect(result.generation.timeMs == 15000)
        #expect(result.generation.model == "claude-sonnet-4-5-20250514")
    }

    @Test func generateProgramRequiresAuth() async throws {
        let (service, sessionID) = createService(authProvider: MockAuthTokenProvider(token: nil))

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 200)
        }

        let request = GenerateProgramRequest(
            inspirationSource: "PPL",
            daysPerWeek: 4,
            sessionDurationMinutes: 60,
            experienceLevel: "intermediate",
            goal: "hypertrophy",
            equipment: ["barbell"],
            useTrainingHistory: false,
            manualStrengthData: nil,
            freeTextPreferences: nil
        )

        do {
            _ = try await service.generateProgram(request)
            Issue.record("Expected unauthorized error")
        } catch let error as RepositoryError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized, got \(error)")
            }
        }
    }

    // MARK: - fetchGenerationStatus Tests

    @Test func fetchGenerationStatusBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/ai/generation-status") == true)
            #expect(request.httpMethod == "GET")
            return MockURLProtocol.errorResponse(for: request.url!, statusCode: 401)
        }

        do {
            _ = try await service.fetchGenerationStatus()
        } catch {
            // Expected
        }
    }

    @Test func fetchGenerationStatusDecodesResponse() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let json: [String: Any] = [
                "generationsUsed": 1,
                "generationsLimit": 3,
                "generationsRemaining": 2,
                "resetsAt": "2026-04-01T00:00:00.000Z",
                "tier": "free"
            ]
            let data = try! JSONSerialization.data(withJSONObject: json)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let result = try await service.fetchGenerationStatus()
        #expect(result.generationsUsed == 1)
        #expect(result.generationsLimit == 3)
        #expect(result.generationsRemaining == 2)
        #expect(result.tier == "free")
    }

    // MARK: - Strength Profile Tests

    @Test func saveStrengthProfileBuildsCorrectRequest() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/ai/strength-profile") == true)
            #expect(request.httpMethod == "PUT")

            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
               let entries = json["entries"] as? [[String: Any]] {
                #expect(entries.count == 1)
                #expect(entries[0]["exerciseName"] as? String == "Squat")
                #expect(entries[0]["weight"] as? Double == 225)
            }

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        let request = StrengthProfileRequest(entries: [
            StrengthDataEntry(exerciseName: "Squat", weight: 225, unit: "lb", reps: 5, sets: 3)
        ])

        try await service.saveStrengthProfile(request)
    }

    @Test func fetchStrengthProfileDecodesResponse() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            #expect(request.url?.path.contains("api/ai/strength-profile") == true)
            #expect(request.httpMethod == "GET")

            let json: [String: Any] = [
                "entries": [
                    [
                        "exerciseName": "Bench Press",
                        "weight": 185,
                        "unit": "lb",
                        "reps": 8,
                        "sets": 3,
                        "matchedExerciseId": "ex_bench"
                    ] as [String: Any]
                ]
            ]
            let data = try! JSONSerialization.data(withJSONObject: json)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let result = try await service.fetchStrengthProfile()
        #expect(result.entries.count == 1)
        #expect(result.entries[0].exerciseName == "Bench Press")
        #expect(result.entries[0].weight == 185)
        #expect(result.entries[0].matchedExerciseId == "ex_bench")
    }

    // MARK: - Error Handling Tests

    @Test func handlesRateLimiting() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: ["Retry-After": "60"]
            )!
            return (response, nil)
        }

        do {
            _ = try await service.fetchGenerationStatus()
            Issue.record("Expected rateLimited error")
        } catch let error as RepositoryError {
            if case .rateLimited(let retryAfter) = error {
                #expect(retryAfter == 60)
            } else {
                Issue.record("Expected rateLimited, got \(error)")
            }
        }
    }

    @Test func handles422Validation() async throws {
        let (service, sessionID) = createService()

        MockURLProtocol.setRequestHandler(for: sessionID) { request in
            return MockURLProtocol.errorResponse(
                for: request.url!,
                statusCode: 422,
                message: "daysPerWeek must be between 1 and 7"
            )
        }

        let request = GenerateProgramRequest(
            inspirationSource: "PPL",
            daysPerWeek: 10,
            sessionDurationMinutes: 60,
            experienceLevel: "intermediate",
            goal: "hypertrophy",
            equipment: ["barbell"],
            useTrainingHistory: false,
            manualStrengthData: nil,
            freeTextPreferences: nil
        )

        do {
            _ = try await service.generateProgram(request)
            Issue.record("Expected validation error")
        } catch let error as RepositoryError {
            if case .validationError = error {
                // Expected
            } else {
                Issue.record("Expected validationError, got \(error)")
            }
        }
    }
}
