//
//  MockUserAPIService.swift
//  Nippardation
//
//  Phase 0 Extension: Mock implementation of UserAPIServiceProtocol for testing and development
//

import Foundation

/// Mock implementation of UserAPIServiceProtocol for testing and development
final class MockUserAPIService: UserAPIServiceProtocol, @unchecked Sendable {

    // MARK: - Test Configuration

    var shouldThrowError = false
    var errorToThrow: RepositoryError = .unauthorized
    var fetchDelay: TimeInterval = 0.1

    /// User to return (if nil, throws unauthorized)
    var mockUser: UserDTO?

    // MARK: - Call Tracking

    private(set) var loginCallCount = 0
    private(set) var fetchProfileCallCount = 0
    private(set) var updateProfileCallCount = 0
    private(set) var lastUpdateRequest: UpdateUserRequest?

    // MARK: - Initialization

    init() {
        // Default mock user
        mockUser = UserDTO(
            id: "mock-user-id",
            firebaseUid: "mock-firebase-uid",
            email: "test@example.com",
            handle: "testuser",
            displayName: "Test User",
            profilePictureUrl: nil,
            bio: "Test bio",
            height: 72,
            weight: 180,
            age: 30,
            gender: "male",
            unitPreference: "imperial",
            isPublicProfile: false,
            totalVolumeLiftedLbs: 50000,
            totalWorkouts: 100,
            currentWorkoutStreak: 5,
            longestWorkoutStreak: 30,
            lastWorkoutDate: Date(),
            notificationsEnabled: true,
            lastSyncedAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Protocol Implementation

    func login() async throws -> UserDTO {
        loginCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        guard let user = mockUser else {
            throw RepositoryError.unauthorized
        }

        return user
    }

    func fetchProfile() async throws -> UserDTO {
        fetchProfileCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        guard let user = mockUser else {
            throw RepositoryError.unauthorized
        }

        return user
    }

    func updateProfile(_ request: UpdateUserRequest) async throws -> UserDTO {
        updateProfileCallCount += 1
        lastUpdateRequest = request

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        guard let existing = mockUser else {
            throw RepositoryError.unauthorized
        }

        // Apply updates
        let updated = UserDTO(
            id: existing.id,
            firebaseUid: existing.firebaseUid,
            email: existing.email,
            handle: existing.handle,
            displayName: request.displayName ?? existing.displayName,
            profilePictureUrl: existing.profilePictureUrl,
            bio: request.bio ?? existing.bio,
            height: request.height ?? existing.height,
            weight: request.weight ?? existing.weight,
            age: request.age ?? existing.age,
            gender: request.gender ?? existing.gender,
            unitPreference: request.unitPreference ?? existing.unitPreference,
            isPublicProfile: request.isPublicProfile ?? existing.isPublicProfile,
            totalVolumeLiftedLbs: existing.totalVolumeLiftedLbs,
            totalWorkouts: existing.totalWorkouts,
            currentWorkoutStreak: existing.currentWorkoutStreak,
            longestWorkoutStreak: existing.longestWorkoutStreak,
            lastWorkoutDate: existing.lastWorkoutDate,
            notificationsEnabled: request.notificationsEnabled ?? existing.notificationsEnabled,
            lastSyncedAt: existing.lastSyncedAt,
            createdAt: existing.createdAt,
            updatedAt: Date()
        )

        mockUser = updated
        return updated
    }

    /// Reset all tracking state
    func reset() {
        loginCallCount = 0
        fetchProfileCallCount = 0
        updateProfileCallCount = 0
        lastUpdateRequest = nil
        shouldThrowError = false
        // Reset to default mock user
        mockUser = UserDTO(
            id: "mock-user-id",
            firebaseUid: "mock-firebase-uid",
            email: "test@example.com",
            handle: "testuser",
            displayName: "Test User",
            profilePictureUrl: nil,
            bio: "Test bio",
            height: 72,
            weight: 180,
            age: 30,
            gender: "male",
            unitPreference: "imperial",
            isPublicProfile: false,
            totalVolumeLiftedLbs: 50000,
            totalWorkouts: 100,
            currentWorkoutStreak: 5,
            longestWorkoutStreak: 30,
            lastWorkoutDate: Date(),
            notificationsEnabled: true,
            lastSyncedAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
