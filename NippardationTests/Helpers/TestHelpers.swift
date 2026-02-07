//
//  TestHelpers.swift
//  NippardationTests
//
//  Common test helpers and sample data
//

import Foundation
@testable import Nippardation

// MARK: - Sample DTOs

enum SampleData {

    // MARK: - Exercises

    static let exerciseDTO = ExerciseDTO(
        id: "ex_001",
        name: "Barbell Bench Press",
        primaryMuscles: ["chest"],
        secondaryMuscles: ["triceps", "shoulders"],
        equipment: "barbell",
        difficulty: "intermediate",
        movementPattern: "push",
        exerciseType: "compound",
        instructions: "Lie on bench, grip bar, lower to chest, press up.",
        videoUrl: "https://example.com/video.mp4",
        thumbnailUrl: "https://example.com/thumb.jpg",
        popularityScore: 95,
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-01T00:00:00Z"
    )

    static let exerciseDTO2 = ExerciseDTO(
        id: "ex_002",
        name: "Barbell Squat",
        primaryMuscles: ["quads", "glutes"],
        secondaryMuscles: ["hamstrings"],
        equipment: "barbell",
        difficulty: "intermediate",
        movementPattern: "squat",
        exerciseType: "compound",
        instructions: "Bar on back, squat down, stand up.",
        videoUrl: nil,
        thumbnailUrl: nil,
        popularityScore: 98,
        createdAt: nil,
        updatedAt: nil
    )

    static let paginationDTO = PaginationDTO(
        page: 1,
        perPage: 20,
        total: 100,
        totalPages: 5
    )

    static let exerciseListResponse = ExerciseListResponse(
        exercises: [exerciseDTO, exerciseDTO2],
        pagination: paginationDTO
    )

    static let exerciseDetailResponse = ExerciseDetailResponse(
        exercise: exerciseDTO
    )

    static let filterOptions = ExerciseFilterOptionsDTO(
        muscleGroups: [
            FilterOptionDTO(value: "chest", label: "Chest", count: 15),
            FilterOptionDTO(value: "back", label: "Back", count: 20)
        ],
        difficulties: [
            FilterOptionDTO(value: "beginner", label: "Beginner", count: 30),
            FilterOptionDTO(value: "intermediate", label: "Intermediate", count: 40)
        ],
        equipment: [
            FilterOptionDTO(value: "barbell", label: "Barbell", count: 25),
            FilterOptionDTO(value: "dumbbell", label: "Dumbbell", count: 30)
        ],
        movementPatterns: [
            FilterOptionDTO(value: "push", label: "Push", count: 20),
            FilterOptionDTO(value: "pull", label: "Pull", count: 20)
        ],
        exerciseTypes: [
            FilterOptionDTO(value: "compound", label: "Compound", count: 50),
            FilterOptionDTO(value: "isolation", label: "Isolation", count: 50)
        ]
    )

    // MARK: - Templates

    static let templateExerciseDTO = TemplateExerciseDTO(
        id: "te_001",
        exerciseId: "ex_001",
        exercise: exerciseDTO,
        orderIndex: 0,
        warmupSets: 2,
        workingSets: 3,
        targetReps: "8-12",
        restSeconds: 90,
        notes: "Focus on form"
    )

    static let templateDTO = TemplateDTO(
        id: "tmpl_001",
        name: "Push Day",
        description: "Chest, shoulders, triceps",
        exercises: [templateExerciseDTO],
        isPublic: false,
        isAiGenerated: false,
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-01T00:00:00Z"
    )

    static let templateListResponse = TemplateListResponse(
        templates: [templateDTO],
        pagination: paginationDTO
    )

    static let templateDetailResponse = TemplateDetailResponse(
        template: templateDTO
    )

    // MARK: - Programs

    static let programWorkoutDTO = ProgramWorkoutDTO(
        id: "pw_001",
        dayNumber: 1,
        dayLabel: "Push Day",
        templateId: "tmpl_001",
        template: templateDTO
    )

    static let programDTO = ProgramDTO(
        id: "prog_001",
        name: "PPL Program",
        description: "Push Pull Legs split",
        daysPerWeek: 6,
        durationWeeks: 12,
        workouts: [programWorkoutDTO],
        isActive: true,
        currentDayIndex: 0,
        timesCompleted: 0,
        isPublic: false,
        isAiGenerated: false,
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-01T00:00:00Z"
    )

    static let programListResponse = ProgramListResponse(
        programs: [programDTO],
        pagination: paginationDTO
    )

    static let programDetailResponse = ProgramDetailResponse(
        program: programDTO
    )

    static let activeProgramDTO = ActiveProgramDTO(
        program: programDTO,
        nextWorkout: programWorkoutDTO,
        isCompleted: false
    )

    // MARK: - User

    static let userDTO = UserDTO(
        id: "user_001",
        firebaseUid: "firebase_123",
        email: "test@example.com",
        handle: "testuser",
        displayName: "Test User",
        profilePictureUrl: nil,
        bio: "Fitness enthusiast",
        height: 180.0,
        weight: 80.0,
        age: 30,
        gender: "male",
        unitPreference: "metric",
        isPublicProfile: true,
        totalVolumeLiftedLbs: "10000.00",
        totalWorkouts: 50,
        currentWorkoutStreak: 5,
        longestWorkoutStreak: 10,
        lastWorkoutDate: "2025-01-15T00:00:00Z",
        pushNotificationTokens: nil,
        notificationsEnabled: true,
        lastSyncedAt: "2025-01-15T00:00:00Z",
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-15T00:00:00Z"
    )

    // MARK: - Sync

    static let syncResponse = SyncResponseDTO(
        success: true,
        syncedAt: "2025-01-15T12:00:00Z",
        conflicts: nil,
        serverData: nil,
        stats: SyncStatsDTO(uploaded: 5, downloaded: 3, conflicts: 0)
    )
}

// MARK: - URL Helpers

extension URL {
    /// Base URL used in tests
    static var testBaseURL: URL {
        URL(string: "https://test-api.example.com")!
    }
}
