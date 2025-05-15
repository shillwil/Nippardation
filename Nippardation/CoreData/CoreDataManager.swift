//
//  CoreDataManager.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/11/25.
//

import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let modelName = "Nippardation"
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        
        // Merge policy to handle conflicts
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Create a background context for operations that should not block the UI
    func backgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Save context
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // MARK: - TrackedWorkout Operations
    
    func saveTrackedWorkout(_ trackedWorkout: TrackedWorkout) {
        let context = backgroundContext()
        
        context.perform {
            // Create the workout entity
            let cdWorkout = CDTrackedWorkout(context: context)
            cdWorkout.id = trackedWorkout.id
            cdWorkout.date = trackedWorkout.date
            cdWorkout.workoutTemplate = trackedWorkout.workoutTemplate
            cdWorkout.duration = trackedWorkout.duration ?? 0
            cdWorkout.isCompleted = trackedWorkout.isCompleted
            cdWorkout.startTime = trackedWorkout.startTime
            cdWorkout.endTime = trackedWorkout.endTime
            
            // Create the exercise entities
            for exercise in trackedWorkout.trackedExercises {
                let cdExercise = CDTrackedExercise(context: context)
                cdExercise.id = exercise.id
                cdExercise.exerciseName = exercise.exerciseName
                cdExercise.muscleGroups = exercise.muscleGroups.map { $0 }
                cdExercise.workout = cdWorkout
                
                // Create the set entities
                for set in exercise.trackedSets {
                    let cdSet = CDTrackedSet(context: context)
                    cdSet.id = set.id
                    cdSet.reps = Int16(set.reps)
                    cdSet.weight = set.weight
                    cdSet.setType = set.setType == .warmup ? 0 : 1
                    cdSet.exerciseTypeName = set.exerciseType.name
                    cdSet.exerciseTypeMuscleGroups = set.exerciseType.muscleGroup.map { $0.rawValue }
                    cdSet.exercise = cdExercise
                }
            }
            
            // Save the context
            do {
                try context.save()
                print("Successfully saved TrackedWorkout to Core Data")
            } catch {
                print("Failed to save TrackedWorkout: \(error)")
                fatalError()
            }
        }
    }
    
    func fetchTrackedWorkouts() -> [TrackedWorkout] {
        let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let cdWorkouts = try viewContext.fetch(request)
            return cdWorkouts.map { self.convertToTrackedWorkout($0) }
        } catch {
            print("Failed to fetch tracked workouts: \(error)")
            return []
        }
    }
    
    func fetchTrackedWorkout(id: UUID) -> TrackedWorkout? {
        let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let cdWorkout = results.first {
                return convertToTrackedWorkout(cdWorkout)
            }
            return nil
        } catch {
            print("Failed to fetch tracked workout: \(error)")
            return nil
        }
    }
    
    func deleteTrackedWorkout(id: UUID) {
        let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if let workout = results.first {
                viewContext.delete(workout)
                saveContext()
                print("Successfully deleted workout")
            }
        } catch {
            print("Failed to delete workout: \(error)")
        }
    }
    
    // MARK: - Workout Statistics
    
    func fetchWorkoutStats() -> [String: Any] {
        let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES")
        
        do {
            let workouts = try viewContext.fetch(request)
            
            let totalWorkouts = workouts.count
            
            var totalSets = 0
            var totalReps = 0
            var totalVolume: Double = 0
            var templateCounts: [String: Int] = [:]
            
            for workout in workouts {
                let exercises = workout.trackedExercisesArray
                
                for exercise in exercises {
                    let sets = exercise.trackedSetsArray
                    totalSets += sets.count
                    
                    for set in sets {
                        totalReps += Int(set.reps)
                        totalVolume += Double(set.reps) * set.weight
                    }
                }
                
                if let template = workout.workoutTemplate {
                    templateCounts[template, default: 0] += 1
                }
            }
            
            return [
                "totalWorkouts": totalWorkouts,
                "totalSets": totalSets,
                "totalReps": totalReps,
                "totalVolume": totalVolume,
                "templateCounts": templateCounts
            ]
            
        } catch {
            print("Failed to fetch workout stats: \(error)")
            return [:]
        }
    }
    
    // MARK: - Exercise Statistics
    
    func fetchExerciseProgressData(exerciseName: String) -> [(date: Date, weight: Double, reps: Int)] {
        let request: NSFetchRequest<CDTrackedExercise> = CDTrackedExercise.fetchRequest()
        request.predicate = NSPredicate(format: "exerciseName == %@", exerciseName)
        request.sortDescriptors = [NSSortDescriptor(key: "workout.date", ascending: true)]
        
        do {
            let exercises = try viewContext.fetch(request)
            var progressData: [(date: Date, weight: Double, reps: Int)] = []
            
            for exercise in exercises {
                if let date = exercise.workout?.date {
                    // Find the best set (highest weight × reps)
                    var bestSet: (weight: Double, reps: Int)? = nil
                    
                    for set in exercise.trackedSetsArray where set.setType == 1 { // Working sets only
                        let volume = set.weight * Double(set.reps)
                        
                        if bestSet == nil || volume > bestSet!.weight * Double(bestSet!.reps) {
                            bestSet = (set.weight, Int(set.reps))
                        }
                    }
                    
                    if let best = bestSet {
                        progressData.append((date: date, weight: best.weight, reps: best.reps))
                    }
                }
            }
            
            return progressData
            
        } catch {
            print("Failed to fetch exercise progress data: \(error)")
            return []
        }
    }
    
    // MARK: - Conversion Helpers
    
    private func convertToTrackedWorkout(_ cdWorkout: CDTrackedWorkout) -> TrackedWorkout {
        let exercises = cdWorkout.trackedExercisesArray
        
        let trackedExercises = exercises.map { cdExercise -> TrackedExercise in
            let sets = cdExercise.trackedSetsArray
            
            let trackedSets = sets.map { cdSet -> TrackedSet in
                let muscleGroups = cdSet.exerciseTypeMuscleGroups?.compactMap {
                    MuscleGroup(rawValue: $0)
                } ?? []
                
                let exerciseType = ExerciseType(
                    name: cdSet.exerciseTypeName ?? "",
                    muscleGroup: muscleGroups
                )
                
                return TrackedSet(
                    reps: Int(cdSet.reps),
                    weight: cdSet.weight,
                    setType: cdSet.setType == 0 ? .warmup : .working,
                    exerciseType: exerciseType
                )
            }
            
            let muscleGroups = cdExercise.muscleGroups?.compactMap { $0 } ?? []
            
            return TrackedExercise(
                id: cdExercise.id ?? UUID(),
                exerciseName: cdExercise.exerciseName ?? "",
                muscleGroups: muscleGroups,
                trackedSets: trackedSets
            )
        }
        
        return TrackedWorkout(
            id: cdWorkout.id ?? UUID(),
            date: cdWorkout.date ?? Date(),
            workoutTemplate: cdWorkout.workoutTemplate ?? "",
            duration: cdWorkout.duration,
            trackedExercises: trackedExercises,
            isCompleted: cdWorkout.isCompleted,
            startTime: cdWorkout.startTime,
            endTime: cdWorkout.endTime
        )
    }
}
