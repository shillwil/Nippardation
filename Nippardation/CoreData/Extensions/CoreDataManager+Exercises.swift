//
//  CoreDataManager+Exercises.swift
//  Nippardation
//
//  Extension for exercise library cache operations
//

import Foundation
import CoreData

// MARK: - Exercise Library Operations

extension CoreDataManager {

    // MARK: - Fetch Operations

    /// Fetch all cached exercises
    func fetchCachedExercises() -> [CDExerciseLibrary] {
        let request: NSFetchRequest<CDExerciseLibrary> = CDExerciseLibrary.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch cached exercises: \(error)")
            return []
        }
    }

    /// Fetch cached exercises with filters
    func fetchCachedExercises(filter: ExerciseFilter?) -> [CDExerciseLibrary] {
        let request: NSFetchRequest<CDExerciseLibrary> = CDExerciseLibrary.fetchRequest()

        var predicates: [NSPredicate] = []

        if let filter = filter {
            // Search text filter
            if !filter.searchText.isEmpty {
                predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", filter.searchText))
            }

            // Equipment filter
            if !filter.equipment.isEmpty {
                let equipmentStrings = filter.equipment.map { $0.rawValue }
                predicates.append(NSPredicate(format: "equipment IN %@", equipmentStrings))
            }

            // Difficulty filter
            if let difficulty = filter.difficulty {
                predicates.append(NSPredicate(format: "difficulty == %@", difficulty.rawValue))
            }

            // Movement pattern filter
            if let movementPattern = filter.movementPattern {
                predicates.append(NSPredicate(format: "movementPattern == %@", movementPattern.rawValue))
            }

            // Exercise type filter
            if let exerciseType = filter.exerciseType {
                predicates.append(NSPredicate(format: "exerciseType == %@", exerciseType.rawValue))
            }
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [
            NSSortDescriptor(key: "popularityScore", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)
        ]

        do {
            var results = try viewContext.fetch(request)

            // Filter by muscle groups in memory (Transformable arrays are hard to query)
            if let filter = filter, !filter.muscleGroups.isEmpty {
                results = results.filter { exercise in
                    let primary = exercise.primaryMusclesArray
                    let secondary = exercise.secondaryMusclesArray
                    let targetMuscleStrings = filter.muscleGroups.map { $0.rawValue }

                    for muscle in targetMuscleStrings {
                        if primary.contains(muscle) || secondary.contains(muscle) {
                            return true
                        }
                    }
                    return false
                }
            }

            return results
        } catch {
            print("Failed to fetch cached exercises with filters: \(error)")
            return []
        }
    }

    /// Fetch a single cached exercise by server ID
    func fetchCachedExercise(serverId: String) -> CDExerciseLibrary? {
        let request: NSFetchRequest<CDExerciseLibrary> = CDExerciseLibrary.fetchRequest()
        request.predicate = NSPredicate(format: "serverId == %@", serverId)
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Failed to fetch cached exercise: \(error)")
            return nil
        }
    }

    /// Fetch popular exercises by popularity score
    func fetchPopularCachedExercises(limit: Int) -> [CDExerciseLibrary] {
        let request: NSFetchRequest<CDExerciseLibrary> = CDExerciseLibrary.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "popularityScore", ascending: false)]
        request.fetchLimit = limit

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch popular exercises: \(error)")
            return []
        }
    }

    /// Fetch exercises by muscle group
    func fetchCachedExercisesByMuscle(_ muscle: MuscleGroup, limit: Int) -> [CDExerciseLibrary] {
        // Since primaryMuscles is a Transformable, we need to fetch all and filter in memory
        let request: NSFetchRequest<CDExerciseLibrary> = CDExerciseLibrary.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "popularityScore", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)
        ]

        do {
            let allExercises = try viewContext.fetch(request)
            let muscleString = muscle.rawValue

            let filtered = allExercises.filter { exercise in
                let primary = exercise.primaryMusclesArray
                return primary.contains(muscleString)
            }

            return Array(filtered.prefix(limit))
        } catch {
            print("Failed to fetch exercises by muscle: \(error)")
            return []
        }
    }

    // MARK: - Save Operations

    /// Cache exercises from domain models
    func cacheExercises(_ exercises: [ExerciseLibraryItem]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                do {
                    for exercise in exercises {
                        // Check if exercise already exists
                        let request: NSFetchRequest<CDExerciseLibrary> = CDExerciseLibrary.fetchRequest()
                        request.predicate = NSPredicate(format: "serverId == %@", exercise.serverId)
                        request.fetchLimit = 1

                        let existing = try context.fetch(request).first
                        let cdExercise = existing ?? CDExerciseLibrary(context: context)

                        cdExercise.id = existing?.id ?? UUID()
                        cdExercise.serverId = exercise.serverId
                        cdExercise.name = exercise.name
                        cdExercise.primaryMuscles = exercise.primaryMuscles.map { $0.rawValue } as NSArray
                        cdExercise.secondaryMuscles = exercise.secondaryMuscles.map { $0.rawValue } as NSArray
                        cdExercise.equipment = exercise.equipment?.rawValue
                        cdExercise.difficulty = exercise.difficulty?.rawValue
                        cdExercise.movementPattern = exercise.movementPattern?.rawValue
                        cdExercise.exerciseType = exercise.exerciseType?.rawValue
                        cdExercise.instructions = exercise.instructions
                        cdExercise.videoUrl = exercise.videoUrl?.absoluteString
                        cdExercise.thumbnailUrl = exercise.thumbnailUrl?.absoluteString
                        cdExercise.popularityScore = Int32(exercise.popularityScore)
                        cdExercise.lastFetchedAt = Date()
                    }

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Caches only exercises that are not in the library cache yet.
    ///
    /// Used for name-only placeholders (an AI generation response, say) so the movement name
    /// survives a Core Data round trip, without ever overwriting a real library entry that
    /// carries muscles, a video and a thumbnail. Placeholders are stored with no
    /// `lastFetchedAt`, which is how they stay recognisable as placeholders on the way back
    /// out and why they are treated as stale and re-fetched when the network is available.
    func cacheExercisesIfAbsent(_ exercises: [ExerciseLibraryItem]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                do {
                    for exercise in exercises {
                        let request: NSFetchRequest<CDExerciseLibrary> = CDExerciseLibrary.fetchRequest()
                        request.predicate = NSPredicate(format: "serverId == %@", exercise.serverId)
                        request.fetchLimit = 1

                        // Never overwrite what is already cached.
                        let existing = try context.fetch(request).first
                        if existing != nil { continue }

                        let cdExercise = CDExerciseLibrary(context: context)
                        cdExercise.id = exercise.id
                        cdExercise.serverId = exercise.serverId
                        cdExercise.name = exercise.name
                        cdExercise.primaryMuscles = exercise.primaryMuscles.map { $0.rawValue } as NSArray
                        cdExercise.secondaryMuscles = exercise.secondaryMuscles.map { $0.rawValue } as NSArray
                        cdExercise.equipment = exercise.equipment?.rawValue
                        cdExercise.difficulty = exercise.difficulty?.rawValue
                        cdExercise.movementPattern = exercise.movementPattern?.rawValue
                        cdExercise.exerciseType = exercise.exerciseType?.rawValue
                        cdExercise.instructions = exercise.instructions
                        cdExercise.videoUrl = exercise.videoUrl?.absoluteString
                        cdExercise.thumbnailUrl = exercise.thumbnailUrl?.absoluteString
                        cdExercise.popularityScore = Int32(exercise.popularityScore)
                        cdExercise.lastFetchedAt = exercise.isPlaceholder ? nil : Date()
                    }

                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Clear exercise cache
    func clearExerciseCache() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<CDExerciseLibrary> = CDExerciseLibrary.fetchRequest()

                do {
                    let exercises = try context.fetch(request)
                    for exercise in exercises {
                        context.delete(exercise)
                    }
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    // MARK: - Conversion

    /// Convert Core Data entity to domain model
    func toDomain(_ cdExercise: CDExerciseLibrary) -> ExerciseLibraryItem {
        ExerciseLibraryItem(
            id: cdExercise.id ?? UUID(),
            serverId: cdExercise.serverId ?? "",
            name: cdExercise.name ?? "",
            primaryMuscles: mapMuscleGroups(cdExercise.primaryMusclesArray),
            secondaryMuscles: mapMuscleGroups(cdExercise.secondaryMusclesArray),
            equipment: cdExercise.equipment.flatMap { Equipment(rawValue: $0) },
            difficulty: cdExercise.difficulty.flatMap { Difficulty(rawValue: $0) },
            movementPattern: cdExercise.movementPattern.flatMap { MovementPattern(rawValue: $0) },
            exerciseType: cdExercise.exerciseType.flatMap { ExerciseCategory(rawValue: $0) },
            instructions: cdExercise.instructions,
            videoUrl: cdExercise.videoUrl.flatMap { URL(string: $0) },
            thumbnailUrl: cdExercise.thumbnailUrl.flatMap { URL(string: $0) },
            popularityScore: Int(cdExercise.popularityScore),
            lastFetchedAt: cdExercise.lastFetchedAt,
            // Rows written by `cacheExercisesIfAbsent` for a name-only placeholder carry no
            // fetch timestamp; every real cache write stamps one.
            isPlaceholder: cdExercise.lastFetchedAt == nil
        )
    }

    /// Map string array to MuscleGroup array
    private func mapMuscleGroups(_ strings: [String]) -> [MuscleGroup] {
        strings.compactMap { MuscleGroup(rawValue: $0) }
    }
}
