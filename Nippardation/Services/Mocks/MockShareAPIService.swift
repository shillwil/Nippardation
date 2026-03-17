//
//  MockShareAPIService.swift
//  Nippardation
//
//  Mock implementation of ShareAPIServiceProtocol for testing and development
//

import Foundation

final class MockShareAPIService: ShareAPIServiceProtocol, @unchecked Sendable {

    // MARK: - Test Configuration

    var shouldThrowError = false
    var errorToThrow: RepositoryError = .networkUnavailable
    var fetchDelay: TimeInterval = 0.1

    // MARK: - Call Tracking

    private(set) var createShareCallCount = 0
    private(set) var fetchShareCallCount = 0

    private(set) var lastCreateType: String?
    private(set) var lastCreateItemId: String?
    private(set) var lastFetchToken: String?

    // MARK: - Protocol Implementation

    func createShare(type: String, itemId: String) async throws -> ShareCreateResponse {
        createShareCallCount += 1
        lastCreateType = type
        lastCreateItemId = itemId

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        let token = "mock_\(UUID().uuidString.prefix(8))"
        return ShareCreateResponse(
            token: token,
            shareUrl: "nippardation://share/\(token)",
            expiresAt: nil
        )
    }

    func fetchShare(token: String) async throws -> ShareDetailResponse {
        fetchShareCallCount += 1
        lastFetchToken = token

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        return Self.sampleShareDetail
    }

    // MARK: - Reset

    func reset() {
        createShareCallCount = 0
        fetchShareCallCount = 0
        lastCreateType = nil
        lastCreateItemId = nil
        lastFetchToken = nil
        shouldThrowError = false
    }
}

// MARK: - Sample Data

extension MockShareAPIService {

    static let sampleShareDetail = ShareDetailResponse(
        token: "mock_abc123",
        type: "program",
        sharedBy: SharedByDTO(
            handle: "jeffnippard",
            displayName: "Jeff Nippard",
            avatarUrl: nil
        ),
        sharedAt: "2026-03-08T12:00:00Z",
        expiresAt: nil,
        template: nil,
        program: ProgramDTO(
            id: "prog_001",
            name: "Upper/Lower Split",
            description: "4-day upper/lower strength program",
            daysPerWeek: 4,
            durationWeeks: 8,
            workouts: [
                ProgramWorkoutDTO(
                    id: "pw_001",
                    dayNumber: 1,
                    dayLabel: "Upper A",
                    templateId: "tmpl_001",
                    template: TemplateDTO(
                        id: "tmpl_001",
                        name: "Upper Body A",
                        description: "Heavy compound upper body",
                        exercises: [
                            TemplateExerciseDTO(
                                id: "te_001",
                                exerciseId: "ex_001",
                                exercise: nil,
                                orderIndex: 0,
                                warmupSets: 2,
                                workingSets: 4,
                                targetReps: "6-8",
                                restSeconds: 180,
                                notes: nil
                            )
                        ],
                        isPublic: false,
                        isAiGenerated: false,
                        createdAt: "2026-01-01T00:00:00Z",
                        updatedAt: "2026-01-01T00:00:00Z"
                    )
                ),
                ProgramWorkoutDTO(
                    id: "pw_002",
                    dayNumber: 2,
                    dayLabel: "Lower A",
                    templateId: "tmpl_002",
                    template: TemplateDTO(
                        id: "tmpl_002",
                        name: "Lower Body A",
                        description: "Heavy compound lower body",
                        exercises: [
                            TemplateExerciseDTO(
                                id: "te_002",
                                exerciseId: "ex_002",
                                exercise: nil,
                                orderIndex: 0,
                                warmupSets: 3,
                                workingSets: 4,
                                targetReps: "5",
                                restSeconds: 240,
                                notes: nil
                            )
                        ],
                        isPublic: false,
                        isAiGenerated: false,
                        createdAt: "2026-01-01T00:00:00Z",
                        updatedAt: "2026-01-01T00:00:00Z"
                    )
                )
            ],
            isActive: false,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: false,
            isAiGenerated: false,
            createdAt: "2026-01-01T00:00:00Z",
            updatedAt: "2026-01-01T00:00:00Z"
        )
    )

    static let sampleTemplateShareDetail = ShareDetailResponse(
        token: "mock_def456",
        type: "template",
        sharedBy: SharedByDTO(
            handle: "alexs",
            displayName: "Alex S",
            avatarUrl: nil
        ),
        sharedAt: "2026-03-08T14:00:00Z",
        expiresAt: nil,
        template: TemplateDTO(
            id: "tmpl_003",
            name: "Push Day",
            description: "Chest, shoulders, and triceps",
            exercises: [
                TemplateExerciseDTO(
                    id: "te_003",
                    exerciseId: "ex_003",
                    exercise: nil,
                    orderIndex: 0,
                    warmupSets: 2,
                    workingSets: 4,
                    targetReps: "8-10",
                    restSeconds: 180,
                    notes: nil
                ),
                TemplateExerciseDTO(
                    id: "te_004",
                    exerciseId: "ex_005",
                    exercise: nil,
                    orderIndex: 1,
                    warmupSets: 1,
                    workingSets: 3,
                    targetReps: "12-15",
                    restSeconds: 90,
                    notes: nil
                )
            ],
            isPublic: false,
            isAiGenerated: false,
            createdAt: "2026-01-01T00:00:00Z",
            updatedAt: "2026-01-01T00:00:00Z"
        ),
        program: nil
    )
}
