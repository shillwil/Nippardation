//
//  WorkoutCacheManager.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/11/25.
//

import Foundation
import Combine

class WorkoutCacheManager {
    static let shared = WorkoutCacheManager()
    
    private let activeWorkoutKey = "activeWorkout"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var timer: Timer?
    private let saveInterval: TimeInterval = 30 // Save every 30 seconds
    
    @Published var activeWorkout: TrackedWorkout?
    
    private init() {
        loadCachedWorkout()
    }
    
    func startWorkout(template: Workout) -> TrackedWorkout {
        // Create tracked exercises from template
        let trackedExercises: [TrackedExercise] = template.exercises.map { exercise in
            let muscleGroupStrings = exercise.type.muscleGroup.map { $0.rawValue }
            return TrackedExercise(
                id: UUID(),
                exerciseName: exercise.type.name,
                muscleGroups: muscleGroupStrings,
                trackedSets: []
            )
        }
        
        // Create tracked workout
        let workout = TrackedWorkout(
            date: Date(),
            workoutTemplate: template.name,
            duration: nil,
            trackedExercises: trackedExercises,
            startTime: Date()
        )
        
        activeWorkout = workout
        startPeriodicSaving()
        return workout
    }
    
    func updateTrackedSet(exerciseIndex: Int, set: TrackedSet) {
        guard var workout = activeWorkout, exerciseIndex < workout.trackedExercises.count else { return }
        
        workout.trackedExercises[exerciseIndex].trackedSets.append(set)
        activeWorkout = workout
        saveWorkoutCache()
    }
    
    func removeTrackedSet(exerciseIndex: Int, setIndex: Int) {
        guard var workout = activeWorkout,
              exerciseIndex < workout.trackedExercises.count,
              setIndex < workout.trackedExercises[exerciseIndex].trackedSets.count else { return }
        
        workout.trackedExercises[exerciseIndex].trackedSets.remove(at: setIndex)
        activeWorkout = workout
        saveWorkoutCache()
    }
    
    func updateSet(exerciseIndex: Int, setIndex: Int, reps: Int, weight: Double) {
        guard var workout = activeWorkout,
              exerciseIndex < workout.trackedExercises.count,
              setIndex < workout.trackedExercises[exerciseIndex].trackedSets.count else { return }
        
        var updatedSet = workout.trackedExercises[exerciseIndex].trackedSets[setIndex]
        updatedSet.reps = reps
        updatedSet.weight = weight
        
        workout.trackedExercises[exerciseIndex].trackedSets[setIndex] = updatedSet
        activeWorkout = workout
        saveWorkoutCache()
    }
    
    func endWorkout() -> TrackedWorkout? {
        guard var workout = activeWorkout else { return nil }
        
        workout.isCompleted = true
        workout.endTime = Date()
        
        if let startTime = workout.startTime {
            workout.duration = Date().timeIntervalSince(startTime)
        }
        
        // Clear the cache
        clearCache()
        stopPeriodicSaving()
        
        // Store in Core Data
        CoreDataManager.shared.saveTrackedWorkout(workout)
        
        return workout
    }
    
    func resumeActiveWorkout() -> TrackedWorkout? {
        return activeWorkout
    }
    
    private func startPeriodicSaving() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: true) { [weak self] _ in
            self?.saveWorkoutCache()
        }
    }
    
    private func stopPeriodicSaving() {
        timer?.invalidate()
        timer = nil
    }
    
    private func saveWorkoutCache() {
        guard let workout = activeWorkout else { return }
        
        do {
            let data = try encoder.encode(workout)
            UserDefaults.standard.set(data, forKey: activeWorkoutKey)
            print("Workout cached successfully")
        } catch {
            print("Failed to cache workout: \(error)")
        }
    }
    
    private func loadCachedWorkout() {
        guard let data = UserDefaults.standard.data(forKey: activeWorkoutKey) else { return }
        
        do {
            let workout = try decoder.decode(TrackedWorkout.self, from: data)
            activeWorkout = workout
            
            // If there's an active workout, restart the timer
            if workout.isCompleted == false {
                startPeriodicSaving()
            }
            
            print("Cached workout loaded successfully")
        } catch {
            print("Failed to load cached workout: \(error)")
        }
    }
    
    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: activeWorkoutKey)
        activeWorkout = nil
    }
}
