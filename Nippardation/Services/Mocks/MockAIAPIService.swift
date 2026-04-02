//
//  MockAIAPIService.swift
//  Nippardation
//
//  Mock implementation of AIAPIServiceProtocol for testing and previews
//

import Foundation

final class MockAIAPIService: AIAPIServiceProtocol, @unchecked Sendable {

    // MARK: - Test Configuration

    var shouldThrowError = false
    var errorToThrow: RepositoryError = .networkUnavailable
    var fetchDelay: TimeInterval = 0.1
    var generateDelay: TimeInterval = 2.0

    // MARK: - Call Tracking

    private(set) var generateProgramCallCount = 0
    private(set) var fetchGenerationStatusCallCount = 0
    private(set) var saveStrengthProfileCallCount = 0
    private(set) var fetchStrengthProfileCallCount = 0

    private(set) var lastGenerateRequest: GenerateProgramRequest?

    // MARK: - Protocol Implementation

    func generateProgram(_ request: GenerateProgramRequest) async throws -> GenerateProgramResponse {
        generateProgramCallCount += 1
        lastGenerateRequest = request

        if generateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(generateDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        return Self.sampleGenerateResponse
    }

    func fetchGenerationStatus() async throws -> GenerationStatusResponse {
        fetchGenerationStatusCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        return Self.sampleGenerationStatus
    }

    func saveStrengthProfile(_ request: StrengthProfileRequest) async throws {
        saveStrengthProfileCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }
    }

    func fetchStrengthProfile() async throws -> StrengthProfileResponse {
        fetchStrengthProfileCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        return Self.sampleStrengthProfile
    }

    // MARK: - Reset

    func reset() {
        generateProgramCallCount = 0
        fetchGenerationStatusCallCount = 0
        saveStrengthProfileCallCount = 0
        fetchStrengthProfileCallCount = 0
        lastGenerateRequest = nil
        shouldThrowError = false
    }
}

// MARK: - Sample Data

extension MockAIAPIService {

    static let sampleGenerationStatus = GenerationStatusResponse(
        generationsUsed: 1,
        generationsLimit: 3,
        generationsRemaining: 2,
        resetsAt: "2026-04-01T00:00:00.000Z",
        tier: "free"
    )

    static let sampleStrengthProfile = StrengthProfileResponse(
        entries: [
            StrengthProfileEntryDTO(
                exerciseName: "Bench Press",
                weight: 185,
                unit: "lb",
                reps: 8,
                sets: 3,
                matchedExerciseId: "ex_bench"
            ),
            StrengthProfileEntryDTO(
                exerciseName: "Squat",
                weight: 225,
                unit: "lb",
                reps: 5,
                sets: 3,
                matchedExerciseId: "ex_squat"
            )
        ]
    )

    static let sampleGenerateResponse = GenerateProgramResponse(
        program: AIGeneratedProgramDTO(
            id: "ai_prog_001",
            name: "AI Hypertrophy Program",
            description: "A personalized 4-day hypertrophy program.",
            daysPerWeek: 4,
            durationWeeks: 8,
            isAiGenerated: true,
            aiPrompt: "Push Pull Legs",
            workouts: [
                AIGeneratedWorkoutDTO(
                    dayNumber: 0,
                    dayLabel: "Push Day",
                    template: AIGeneratedTemplateDTO(
                        id: "ai_tmpl_001",
                        name: "Push Day",
                        description: "Chest, shoulders, and triceps",
                        exerciseCount: 2,
                        wasReused: true,
                        exercises: [
                            AIGeneratedExerciseDTO(exerciseId: "ex_bench", name: "Bench Press", warmupSets: 2, workingSets: 4, targetReps: "8-10", restSeconds: 120, notes: nil),
                            AIGeneratedExerciseDTO(exerciseId: "ex_ohp", name: "Overhead Press", warmupSets: 1, workingSets: 3, targetReps: "8-12", restSeconds: 90, notes: nil)
                        ]
                    )
                ),
                AIGeneratedWorkoutDTO(
                    dayNumber: 1,
                    dayLabel: "Pull Day",
                    template: AIGeneratedTemplateDTO(
                        id: "ai_tmpl_002",
                        name: "Pull Day",
                        description: "Back and biceps",
                        exerciseCount: 1,
                        wasReused: false,
                        exercises: [
                            AIGeneratedExerciseDTO(exerciseId: "ex_row", name: "Barbell Row", warmupSets: 2, workingSets: 4, targetReps: "6-8", restSeconds: 120, notes: nil)
                        ]
                    )
                )
            ],
            createdAt: "2026-03-23T00:00:00Z",
            updatedAt: "2026-03-23T00:00:00Z"
        ),
        generation: GenerationMetadataDTO(
            timeMs: 15000,
            model: "claude-sonnet-4-5-20250514",
            personalizationApplied: true,
            usedTrainingHistory: false,
            personalizationSource: "none"
        )
    )
}
