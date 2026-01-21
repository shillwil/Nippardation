//
//  DependencyContainer.swift
//  Nippardation
//
//  Phase 0: Dependency injection container for service protocols
//

import Foundation

/// Container for managing dependencies throughout the app
/// Provides protocol-based access to services for easy testing and swapping implementations
@MainActor
final class DependencyContainer: ObservableObject {

    // MARK: - Singleton

    static let shared = DependencyContainer()

    // MARK: - Service Instances

    /// Exercise repository for fetching and caching exercises
    @Published private(set) var exerciseRepository: any ExerciseRepositoryProtocol

    /// Template repository for managing workout templates
    @Published private(set) var templateRepository: any TemplateRepositoryProtocol

    /// Program repository for managing workout programs
    @Published private(set) var programRepository: any ProgramRepositoryProtocol

    /// Workout repository for managing completed workouts
    @Published private(set) var workoutRepository: any WorkoutRepositoryProtocol

    /// Sync service for syncing data with the server
    @Published private(set) var syncService: any SyncServiceProtocol

    /// Video cache service for caching exercise videos
    @Published private(set) var videoCacheService: any VideoCacheServiceProtocol

    /// Network monitor for tracking connectivity
    @Published private(set) var networkMonitor: NetworkMonitor

    // MARK: - Initialization

    private init() {
        // Initialize with mock implementations by default
        // Real implementations will be registered in AppDelegate/SceneDelegate
        self.exerciseRepository = MockExerciseRepository()
        self.templateRepository = MockTemplateRepository()
        self.programRepository = MockProgramRepository()
        self.workoutRepository = MockWorkoutRepository()
        self.syncService = MockSyncService()
        self.videoCacheService = MockVideoCacheService()
        self.networkMonitor = NetworkMonitor()
    }

    // MARK: - Registration

    /// Registers a custom exercise repository
    func register(exerciseRepository: any ExerciseRepositoryProtocol) {
        self.exerciseRepository = exerciseRepository
    }

    /// Registers a custom template repository
    func register(templateRepository: any TemplateRepositoryProtocol) {
        self.templateRepository = templateRepository
    }

    /// Registers a custom program repository
    func register(programRepository: any ProgramRepositoryProtocol) {
        self.programRepository = programRepository
    }

    /// Registers a custom workout repository
    func register(workoutRepository: any WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }

    /// Registers a custom sync service
    func register(syncService: any SyncServiceProtocol) {
        self.syncService = syncService
    }

    /// Registers a custom video cache service
    func register(videoCacheService: any VideoCacheServiceProtocol) {
        self.videoCacheService = videoCacheService
    }

    // MARK: - Configuration

    /// Configures the container with production services
    /// Called during app initialization
    func configureForProduction() {
        // TODO: Replace with real implementations when available
        // self.exerciseRepository = ExerciseRepository()
        // self.templateRepository = TemplateRepository()
        // etc.
    }

    /// Configures the container with mock services for testing/previews
    func configureForTesting() {
        self.exerciseRepository = MockExerciseRepository()
        self.templateRepository = MockTemplateRepository()
        self.programRepository = MockProgramRepository()
        self.workoutRepository = MockWorkoutRepository()
        self.syncService = MockSyncService()
        self.videoCacheService = MockVideoCacheService()
    }

    /// Resets all services to their default state
    func reset() {
        configureForTesting()
    }
}

// MARK: - Preview Support

extension DependencyContainer {

    /// Creates a container configured for SwiftUI previews
    static var preview: DependencyContainer {
        let container = DependencyContainer()
        container.configureForTesting()
        return container
    }

    /// Creates a container with a delay to simulate network latency
    static var previewWithDelay: DependencyContainer {
        let container = DependencyContainer()
        container.configureForTesting()

        // Add delays to simulate network
        if let mock = container.exerciseRepository as? MockExerciseRepository {
            mock.setDelay(0.5)
        }
        if let mock = container.templateRepository as? MockTemplateRepository {
            mock.setDelay(0.5)
        }
        if let mock = container.programRepository as? MockProgramRepository {
            mock.setDelay(0.5)
        }
        if let mock = container.syncService as? MockSyncService {
            mock.setDelay(1.0)
        }

        return container
    }

    /// Creates a container that simulates failures
    static var previewWithFailures: DependencyContainer {
        let container = DependencyContainer()
        container.configureForTesting()

        // Configure mocks to fail
        if let mock = container.exerciseRepository as? MockExerciseRepository {
            mock.setFailure(true)
        }
        if let mock = container.templateRepository as? MockTemplateRepository {
            mock.setFailure(true)
        }
        if let mock = container.programRepository as? MockProgramRepository {
            mock.setFailure(true)
        }
        if let mock = container.syncService as? MockSyncService {
            mock.setFailure(true)
        }

        return container
    }
}

// MARK: - Environment Key

import SwiftUI

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

extension View {
    /// Injects the dependency container into the view hierarchy
    func withDependencies(_ container: DependencyContainer) -> some View {
        environment(\.dependencies, container)
    }
}
