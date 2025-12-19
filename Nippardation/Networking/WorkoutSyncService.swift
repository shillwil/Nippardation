//
//  WorkoutSyncService.swift
//  Nippardation
//
//  Handles synchronization of workout data with the backend
//

import Foundation
import UIKit

// MARK: - Sync Data Models (matching backend expectations)

struct SyncPayload: Codable {
    let deviceId: String
    let deviceInfo: DeviceInfo?
    let lastSyncTimestamp: String?
    let workouts: [WorkoutSyncData]
}

struct DeviceInfo: Codable {
    let name: String?
    let type: String
    let appVersion: String
    let osVersion: String?
}

struct WorkoutSyncData: Codable {
    let clientId: String
    let userId: String
    let date: String
    let name: String?
    let durationSeconds: Int?
    let isCompleted: Bool
    let startTime: String?
    let endTime: String?
    let templateName: String?
    let exercises: [ExerciseSyncData]
    let updatedAt: String
}

struct ExerciseSyncData: Codable {
    let clientId: String
    let exerciseName: String
    let muscleGroups: [String]
    let sets: [SetSyncData]
    let updatedAt: String
}

struct SetSyncData: Codable {
    let clientId: String
    let reps: Int
    let weight: Double
    let setType: String
    let exerciseTypeName: String
    let exerciseTypeMuscleGroups: [String]
    let updatedAt: String
}

// MARK: - Sync Response Models

struct SyncResponse: Decodable {
    let success: Bool
    let message: String?
    let data: SyncResponseData?
}

struct SyncResponseData: Decodable {
    let syncedAt: String
    let conflicts: [ConflictData]?
    let serverData: ServerData?
    let stats: SyncStats?
}

struct ConflictData: Decodable {
    let entityType: String
    let entityId: String
    let resolution: String
}

struct ServerData: Decodable {
    let workouts: [WorkoutSyncData]
    let lastServerSync: String
}

struct SyncStats: Decodable {
    let uploaded: Int
    let downloaded: Int
    let conflicts: Int
}

// MARK: - Sync Service

class WorkoutSyncService {
    static let shared = WorkoutSyncService()
    
    private let networkManager = NetworkManager.shared
    private let dateFormatter = ISO8601DateFormatter()
    
    private init() {
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }
    
    // MARK: - Device ID Management
    
    private var deviceId: String {
        if let savedId = UserDefaults.standard.string(forKey: "device_id") {
            return savedId
        }
        
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "device_id")
        return newId
    }
    
    private var lastSyncTimestamp: Date? {
        get {
            UserDefaults.standard.object(forKey: "last_sync_timestamp") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "last_sync_timestamp")
        }
    }
    
    // MARK: - Public Methods
    
    /// Sync a completed workout with the backend
    func syncCompletedWorkout(_ workout: TrackedWorkout) async throws {
        guard let userId = AuthManager.shared.currentUser?.uid else {
            #if DEBUG
            print("❌ Sync failed: No authenticated user")
            #endif
            throw NetworkError.unauthorized
        }
        
        #if DEBUG
        print("📤 Starting workout sync...")
        print("   Environment: \(AppConfiguration.shared.environment.rawValue)")
        print("   API URL: \(AppConfiguration.shared.baseURL)")
        print("   Workout: \(workout.workoutTemplate) on \(workout.formattedDate)")
        #endif
        
        let syncData = transformWorkoutToSyncData(workout, userId: userId)
        let payload = SyncPayload(
            deviceId: deviceId,
            deviceInfo: getDeviceInfo(),
            lastSyncTimestamp: lastSyncTimestamp?.iso8601String,
            workouts: [syncData]
        )
        
        do {
            let response = try await networkManager.post(
                path: "/api/sync",
                body: payload,
                responseType: SyncResponse.self
            )
            
            if response.success {
                lastSyncTimestamp = Date()

                #if DEBUG
                print("✅ Workout synced successfully")

                // Handle any conflicts
                if let conflicts = response.data?.conflicts, !conflicts.isEmpty {
                    print("⚠️ Sync conflicts detected: \(conflicts.count)")
                }

                // Process any server data
                if let serverWorkouts = response.data?.serverData?.workouts {
                    print("📥 Received \(serverWorkouts.count) workouts from server")
                }

                // Print sync stats if available
                if let stats = response.data?.stats {
                    print("📊 Sync stats - Uploaded: \(stats.uploaded), Downloaded: \(stats.downloaded), Conflicts: \(stats.conflicts)")
                }
                #endif
            } else {
                let errorMsg = response.message ?? "Sync failed"
                throw NetworkError.serverError(errorMsg)
            }
        } catch {
            #if DEBUG
            print("❌ Sync error: \(error)")

            // Provide more detailed error information
            if let networkError = error as? NetworkError {
                switch networkError {
                case .unauthorized:
                    print("   → Authentication failed. Token may be expired.")
                case .serverError(let message):
                    print("   → Server error: \(message)")
                case .invalidURL:
                    print("   → Invalid API URL configuration")
                case .noData:
                    print("   → No data received from server")
                case .decodingError:
                    print("   → Failed to decode server response")
                case .unknown(let underlyingError):
                    print("   → Unknown error: \(underlyingError.localizedDescription)")
                }
            }
            #endif

            throw error
        }
    }
    
    /// Sync all pending workouts
    func syncAllPendingWorkouts() async throws {
        guard let userId = AuthManager.shared.currentUser?.uid else {
            throw NetworkError.unauthorized
        }
        
        // Get all completed workouts from Core Data that haven't been synced
        let unsyncedWorkouts = try await CoreDataManager.shared.getUnsyncedWorkouts()
        
        if unsyncedWorkouts.isEmpty {
            #if DEBUG
            print("✅ No workouts to sync")
            #endif
            return
        }

        #if DEBUG
        print("📤 Syncing \(unsyncedWorkouts.count) workouts...")
        #endif
        
        let syncDataArray = unsyncedWorkouts.map { transformWorkoutToSyncData($0, userId: userId) }
        let payload = SyncPayload(
            deviceId: deviceId,
            deviceInfo: getDeviceInfo(),
            lastSyncTimestamp: lastSyncTimestamp?.iso8601String,
            workouts: syncDataArray
        )
        
        let response = try await networkManager.post(
            path: "/api/sync",
            body: payload,
            responseType: SyncResponse.self
        )
        
        if response.success {
            lastSyncTimestamp = Date()

            // Mark workouts as synced in Core Data
            try await CoreDataManager.shared.markWorkoutsAsSynced(unsyncedWorkouts)

            #if DEBUG
            print("✅ Successfully synced \(unsyncedWorkouts.count) workouts")
            #endif
        } else {
            throw NetworkError.serverError(response.message ?? "Sync failed")
        }
    }
    
    // MARK: - Data Transformation
    
    private func transformWorkoutToSyncData(_ workout: TrackedWorkout, userId: String) -> WorkoutSyncData {
        let updatedAt = dateFormatter.string(from: Date())
        
        let exercises = workout.trackedExercises.map { exercise in
            let sets = exercise.trackedSets.map { set in
                SetSyncData(
                    clientId: set.id.uuidString,
                    reps: set.reps,
                    weight: set.weight,
                    setType: set.setType.rawValue,
                    exerciseTypeName: set.exerciseType.name,
                    exerciseTypeMuscleGroups: set.exerciseType.muscleGroup.map { $0.rawValue },
                    updatedAt: updatedAt
                )
            }
            
            return ExerciseSyncData(
                clientId: exercise.id.uuidString,
                exerciseName: exercise.exerciseName,
                muscleGroups: exercise.muscleGroups,
                sets: sets,
                updatedAt: updatedAt
            )
        }
        
        return WorkoutSyncData(
            clientId: workout.id.uuidString,
            userId: userId,
            date: dateFormatter.string(from: workout.date),
            name: workout.workoutTemplate,
            durationSeconds: workout.duration != nil ? Int(workout.duration!) : nil,
            isCompleted: workout.isCompleted,
            startTime: workout.startTime != nil ? dateFormatter.string(from: workout.startTime!) : nil,
            endTime: workout.endTime != nil ? dateFormatter.string(from: workout.endTime!) : nil,
            templateName: workout.workoutTemplate,
            exercises: exercises,
            updatedAt: updatedAt
        )
    }
    
    private func getDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        return DeviceInfo(
            name: nil,  // Don't send personal device name (PII)
            type: "ios",
            appVersion: appVersion,
            osVersion: device.systemVersion
        )
    }
}

// MARK: - Date Extension

private extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}

// MARK: - Core Data Extension

extension CoreDataManager {
    func getUnsyncedWorkouts() async throws -> [TrackedWorkout] {
        // This method should be implemented in CoreDataManager
        // to fetch workouts that haven't been synced
        // For now, returning empty array
        return []
    }
    
    func markWorkoutsAsSynced(_ workouts: [TrackedWorkout]) async throws {
        // This method should be implemented in CoreDataManager
        // to mark workouts as synced
    }
}