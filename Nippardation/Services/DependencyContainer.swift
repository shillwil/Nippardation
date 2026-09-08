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

    /// Fills in missing exercise library items on template exercises (local cache first,
    /// then the exercise API). Used by the repositories and by the view models that build
    /// templates locally, so real movement names show everywhere.
    @Published private(set) var exerciseLibraryResolver: ExerciseLibraryResolver

    // MARK: - API Services

    /// Exercise API service for API-level operations
    @Published private(set) var exerciseAPIService: any ExerciseAPIServiceProtocol

    /// Template API service for API-level operations
    @Published private(set) var templateAPIService: any TemplateAPIServiceProtocol

    /// Program API service for API-level operations
    @Published private(set) var programAPIService: any ProgramAPIServiceProtocol

    /// Sync API service for API-level operations
    @Published private(set) var syncAPIService: any SyncAPIServiceProtocol

    /// User API service for API-level operations
    @Published private(set) var userAPIService: any UserAPIServiceProtocol

    /// Share API service for sharing programs and templates
    @Published private(set) var shareAPIService: any ShareAPIServiceProtocol

    /// AI API service for AI-powered program generation
    @Published private(set) var aiAPIService: any AIAPIServiceProtocol

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
        self.exerciseLibraryResolver = ExerciseLibraryResolver()

        // Initialize API services with mocks
        self.exerciseAPIService = MockExerciseAPIService()
        self.templateAPIService = MockTemplateAPIService()
        self.programAPIService = MockProgramAPIService()
        self.syncAPIService = MockSyncAPIService()
        self.userAPIService = MockUserAPIService()
        self.shareAPIService = MockShareAPIService()
        self.aiAPIService = MockAIAPIService()
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
        let authProvider = DefaultAuthTokenProvider.shared

        // API services
        let exerciseAPI = ExerciseAPIService(authProvider: authProvider)
        let templateAPI = TemplateAPIService(authProvider: authProvider)
        let programAPI = ProgramAPIService(authProvider: authProvider)
        let syncAPI = SyncAPIService(authProvider: authProvider)
        let userAPI = UserAPIService(authProvider: authProvider)
        let shareAPI = ShareAPIService(authProvider: authProvider)
        let aiAPI = AIAPIService(authProvider: authProvider)

        self.exerciseAPIService = exerciseAPI
        self.templateAPIService = templateAPI
        self.programAPIService = programAPI
        self.syncAPIService = syncAPI
        self.userAPIService = userAPI
        self.shareAPIService = shareAPI
        self.aiAPIService = aiAPI

        // Repositories
        let workoutRepository = WorkoutRepository(coreDataManager: .shared)
        let exerciseRepository = ExerciseRepository(apiService: exerciseAPI, coreDataManager: .shared)
        let templateRepository = TemplateRepository(apiService: templateAPI, coreDataManager: .shared, exerciseAPIService: exerciseAPI)
        let programRepository = ProgramRepository(apiService: programAPI, coreDataManager: .shared, exerciseAPIService: exerciseAPI)

        self.exerciseLibraryResolver = ExerciseLibraryResolver(
            coreDataManager: .shared,
            exerciseAPIService: exerciseAPI
        )

        self.workoutRepository = workoutRepository
        self.exerciseRepository = exerciseRepository
        self.templateRepository = templateRepository
        self.programRepository = programRepository

        // Services
        self.syncService = SyncService(
            apiService: syncAPI,
            workoutRepository: workoutRepository,
            templateRepository: templateRepository,
            programRepository: programRepository,
            coreDataManager: .shared
        )
        self.videoCacheService = VideoCacheService(
            templateRepository: templateRepository,
            programRepository: programRepository
        )
    }

    /// Configures the container with mock services for testing/previews
    func configureForTesting() {
        self.exerciseLibraryResolver = ExerciseLibraryResolver()
        self.exerciseRepository = MockExerciseRepository()
        self.templateRepository = MockTemplateRepository()
        self.programRepository = MockProgramRepository()
        self.workoutRepository = MockWorkoutRepository()
        self.syncService = MockSyncService()
        self.videoCacheService = MockVideoCacheService()

        // Reset API services to mocks
        self.exerciseAPIService = MockExerciseAPIService()
        self.templateAPIService = MockTemplateAPIService()
        self.programAPIService = MockProgramAPIService()
        self.syncAPIService = MockSyncAPIService()
        self.userAPIService = MockUserAPIService()
        self.shareAPIService = MockShareAPIService()
        self.aiAPIService = MockAIAPIService()
    }

    // MARK: - API Service Setters (Used by Agent A)

    /// Replace exercise API service with real implementation
    /// Called by Agent A after completion
    func setExerciseAPIService(_ service: any ExerciseAPIServiceProtocol) {
        self.exerciseAPIService = service
    }

    /// Replace template API service with real implementation
    /// Called by Agent A after completion
    func setTemplateAPIService(_ service: any TemplateAPIServiceProtocol) {
        self.templateAPIService = service
    }

    /// Replace program API service with real implementation
    /// Called by Agent A after completion
    func setProgramAPIService(_ service: any ProgramAPIServiceProtocol) {
        self.programAPIService = service
    }

    /// Replace sync API service with real implementation
    /// Called by Agent A after completion
    func setSyncAPIService(_ service: any SyncAPIServiceProtocol) {
        self.syncAPIService = service
    }

    /// Replace user API service with real implementation
    /// Called by Agent A after completion
    func setUserAPIService(_ service: any UserAPIServiceProtocol) {
        self.userAPIService = service
    }

    /// Replace share API service with real implementation
    func setShareAPIService(_ service: any ShareAPIServiceProtocol) {
        self.shareAPIService = service
    }

    /// Replace AI API service with real implementation
    func setAIAPIService(_ service: any AIAPIServiceProtocol) {
        self.aiAPIService = service
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
