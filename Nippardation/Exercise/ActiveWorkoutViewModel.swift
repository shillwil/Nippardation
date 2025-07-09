//
//  ActiveWorkoutViewModel.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/17/25.
//

import Foundation
import Combine

class ActiveWorkoutViewModel: ObservableObject {
    // Published properties that the view will observe
    @Published var workout: TrackedWorkout
    @Published var totalVolume: Double = 0
    @Published var completedSets: Int = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isShowingEndWorkoutAlert = false
    @Published var volumeUnit: VolumeUnit = .pounds
    
    // Timer for tracking workout duration
    private var timer: Timer?
    
    // Dependencies
    private let workoutManager = WorkoutManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(workout: TrackedWorkout) {
        self.workout = workout
        
        // Subscribe to workout manager updates
        workoutManager.$activeWorkout
            .compactMap { $0 }
            .sink { [weak self] updatedWorkout in
                self?.workout = updatedWorkout
                self?.updateWorkoutStats()
            }
            .store(in: &cancellables)
        
        // Calculate initial stats
        updateWorkoutStats()
        
        // Set initial elapsed time based on workout start time
        if let startTime = workout.startTime {
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
    
    // MARK: - Timer Management
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedTime += 1
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Workout Management
    
    func updateWorkout(_ newWorkout: TrackedWorkout) {
        self.workout = newWorkout
        updateWorkoutStats()
    }
    
    func updateExercise(at index: Int, with exercise: TrackedExercise) {
        guard index < workout.trackedExercises.count else { return }
        
        // Update local workout model
        workout.trackedExercises[index] = exercise
        
        // Update in WorkoutManager
        workoutManager.updateExercise(at: index, with: exercise)
        
        // Recalculate stats
        updateWorkoutStats()
    }
    
    func endWorkout() {
        workoutManager.endWorkout()
        stopTimer()
    }
    
    // MARK: - Stats Calculation
    
    func updateWorkoutStats() {
        // Calculate total volume
        totalVolume = workout.trackedExercises.reduce(0.0) { exerciseSum, exercise in
            exerciseSum + exercise.trackedSets.reduce(0.0) { setSum, set in
                setSum + (Double(set.reps) * set.weight)
            }
        }
        
        // Count completed sets
        completedSets = workout.trackedExercises.reduce(0) { $0 + $1.trackedSets.count }
    }
    
    // MARK: - Formatted Time
    
    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Volume Management
    
    func cycleVolumeUnit() {
        volumeUnit = volumeUnit.next()
    }
    
    var formattedTotalVolume: String {
        let convertedVolume = volumeUnit.convert(totalVolume, from: .pounds)
        return volumeUnit.format(convertedVolume)
    }
}
