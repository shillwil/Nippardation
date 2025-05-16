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
        // Check for an active workout in the cache
        if let cachedWorkout = cacheManager.resumeActiveWorkout() {
            activeWorkout = cachedWorkout
            isWorkoutInProgress = true
        }
        
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
    
    func startWorkout(template: Workout) -> TrackedWorkout {
        let workout = cacheManager.startWorkout(template: template)
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
    
    func updateSet(exerciseIndex: Int, setIndex: Int, reps: Int, weight: Double) {
        cacheManager.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: reps, weight: weight)
    }
    
    func removeTrackedSet(exerciseIndex: Int, setIndex: Int) {
        cacheManager.removeTrackedSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
    }
    
    func endWorkout() {
        guard let completedWorkout = cacheManager.endWorkout() else { return }
        
        self.isWorkoutInProgress = false
        self.activeWorkout = nil
        
        // Reload completed workouts and stats
        loadCompletedWorkouts()
        loadWorkoutStats()
    }
    
    func deleteCompletedWorkout(id: UUID) {
        coreDataManager.deleteTrackedWorkout(id: id)
        loadCompletedWorkouts()
        loadWorkoutStats()
    }
    
    func getExerciseProgress(exerciseName: String) -> [(date: Date, weight: Double, reps: Int)] {
        return coreDataManager.fetchExerciseProgressData(exerciseName: exerciseName)
    }
    
    private func loadCompletedWorkouts() {
        completedWorkouts = coreDataManager.fetchTrackedWorkouts()
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }
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
            $0.date >= startDate
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
