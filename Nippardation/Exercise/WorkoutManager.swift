//
//  WorkoutManager.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/11/25.
//

import Foundation
import Combine
import SwiftUI

class WorkoutManager: ObservableObject {
    static let shared = WorkoutManager()
    
    private let cacheManager = WorkoutCacheManager.shared
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var activeWorkout: TrackedWorkout?
    @Published var completedWorkouts: [TrackedWorkout] = []
    @Published var isWorkoutInProgress: Bool = false
    @Published var workoutStats: WorkoutStats = WorkoutStats()
    
    private init() {
        // Initial check for cached workout - this will be done on app start
        checkForActiveWorkout()
        
        // Load completed workouts from Core Data
        loadCompletedWorkouts()
        
        // Subscribe to active workout changes
        cacheManager.$activeWorkout
            .sink { [weak self] workout in
                self?.activeWorkout = workout
                self?.isWorkoutInProgress = workout != nil
            }
            .store(in: &cancellables)
        
        // Load workout statistics
        loadWorkoutStats()
    }
    
    // Public method to explicitly check for cached workout
    func checkForActiveWorkout() {
        if let cachedWorkout = cacheManager.resumeActiveWorkout() {
            DispatchQueue.main.async { [weak self] in
                self?.activeWorkout = cachedWorkout
                self?.isWorkoutInProgress = true
                // Ensure UI gets updated
                self?.objectWillChange.send()
            }
            print("Restored active workout: \(cachedWorkout.workoutTemplate)")
        } else {
            print("No active workout found in cache")
        }
    }
    
    func startWorkout(template: Workout) -> TrackedWorkout {
        let userID = AuthManager.shared.user?.uid
        let workout = cacheManager.startWorkout(template: template, userID: userID)
        self.activeWorkout = workout
        self.isWorkoutInProgress = true
        return workout
    }
    
    func updateTrackedSet(exerciseIndex: Int, set: TrackedSet) {
        cacheManager.updateTrackedSet(exerciseIndex: exerciseIndex, set: set)
        
        if let workout = cacheManager.activeWorkout {
            self.activeWorkout = workout
        }
    }
    
    func updateSet(exerciseIndex: Int, setIndex: Int, reps: Int, weight: Double, setType: SetType) {
        cacheManager.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: reps, weight: weight, setType: setType)
    }
    
    func removeTrackedSet(exerciseIndex: Int, setIndex: Int) {
        cacheManager.removeTrackedSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
    }
    
    func updateExercise(at index: Int, with exercise: TrackedExercise) {
        guard var workout = activeWorkout, index < workout.trackedExercises.count else { return }
        
        workout.trackedExercises[index] = exercise
        activeWorkout = workout
        
        // Update in cache
        cacheManager.updateExercise(at: index, with: exercise)
    }
    
    func endWorkout() {
        guard let completedWorkout = cacheManager.endWorkout() else { return }
        
        self.isWorkoutInProgress = false
        self.activeWorkout = nil
        
        // Save to CoreData first
        CoreDataManager.shared.saveTrackedWorkout(completedWorkout)
        
        // Sync workout to backend asynchronously
        Task {
            do {
                try await WorkoutSyncService.shared.syncCompletedWorkout(completedWorkout)
                #if DEBUG
                print("✅ Workout synced to backend successfully")
                #endif
            } catch {
                #if DEBUG
                print("❌ Failed to sync workout: \(error)")
                #endif
                // The workout is already saved locally, so we can handle sync failures gracefully
                // Could implement a retry mechanism or queue for later sync
            }
        }
        
        // Then reload the data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.loadCompletedWorkouts()
            self?.loadWorkoutStats()
            
            // Notify observers that data has changed
            self?.objectWillChange.send()
            
            // Also post notification for any other observers
            NotificationCenter.default.post(name: NSNotification.Name("WorkoutDataUpdated"), object: nil)
        }
    }
    
    func deleteCompletedWorkout(id: UUID) {
        coreDataManager.deleteTrackedWorkout(id: id)
        loadCompletedWorkouts()
        loadWorkoutStats()
    }
    
    func getExerciseProgress(exerciseName: String) -> [(date: Date, weight: Double, reps: Int)] {
        return coreDataManager.fetchExerciseProgressData(exerciseName: exerciseName)
    }
    
    func loadCompletedWorkouts() {
        if let userID = AuthManager.shared.user?.uid {
            completedWorkouts = coreDataManager.fetchTrackedWorkouts(for: userID)
                .filter { $0.isCompleted }
                .sorted { $0.date > $1.date }
        } else {
            completedWorkouts = []
        }
    }
    
    private func loadWorkoutStats() {
        let stats = coreDataManager.fetchWorkoutStats()
        
        workoutStats.totalWorkouts = stats["totalWorkouts"] as? Int ?? 0
        workoutStats.totalSets = stats["totalSets"] as? Int ?? 0
        workoutStats.totalReps = stats["totalReps"] as? Int ?? 0
        workoutStats.totalVolume = stats["totalVolume"] as? Double ?? 0
        workoutStats.templateCounts = stats["templateCounts"] as? [String: Int] ?? [:]
    }
}

// Statistics structure for displaying workout data
struct WorkoutStats {
    var totalWorkouts: Int = 0
    var totalSets: Int = 0
    var totalReps: Int = 0
    var totalVolume: Double = 0
    var templateCounts: [String: Int] = [:]
    
    var formattedTotalVolume: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: totalVolume)) ?? "0"
    }
    
    var mostFrequentTemplate: String {
        return templateCounts.max(by: { $0.value < $1.value })?.key ?? "None"
    }
}

// Extension for chart and analytics helpers
extension WorkoutManager {
    func getVolumeData(for days: Int = 30) -> [(date: Date, volume: Double)] {
        // Filter for workouts in the specified timeframe
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let filteredWorkouts = completedWorkouts.filter {
            $0.date >= startDate && $0.isCompleted
        }
        
        // Group by date (day)
        var volumeByDate: [Date: Double] = [:]
        
        for workout in filteredWorkouts {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: workout.date)
            if let date = calendar.date(from: dateComponents) {
                let workoutVolume = workout.trackedExercises.flatMap { exercise in
                    exercise.trackedSets.map { set in
                        Double(set.reps) * set.weight
                    }
                }.reduce(0, +)
                
                volumeByDate[date, default: 0] += workoutVolume
            }
        }
        
        // Convert to array and sort by date
        let volumeData = volumeByDate.map { (date: $0.key, volume: $0.value) }
            .sorted { $0.date < $1.date }
        
        return volumeData
    }
    
    // Get top exercises by volume
    func getTopExercises(limit: Int = 5) -> [(name: String, volume: Double)] {
        var exerciseVolume: [String: Double] = [:]
        
        for workout in completedWorkouts {
            for exercise in workout.trackedExercises {
                let volume = exercise.trackedSets.reduce(0.0) { total, set in
                    total + (Double(set.reps) * set.weight)
                }
                
                exerciseVolume[exercise.exerciseName, default: 0] += volume
            }
        }
        
        return exerciseVolume.map { (name: $0.key, volume: $0.value) }
            .sorted { $0.volume > $1.volume }
            .prefix(limit)
            .map { (name: $0.name, volume: $0.volume) }
    }
}
