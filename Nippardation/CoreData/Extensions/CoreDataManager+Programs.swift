//
//  CoreDataManager+Programs.swift
//  Nippardation
//
//  Extension for program cache operations
//

import Foundation
import CoreData

// MARK: - Program Operations

extension CoreDataManager {

    // MARK: - Fetch Operations

    /// Fetch all cached programs
    func fetchCachedPrograms() -> [CDProgram] {
        let request: NSFetchRequest<CDProgram> = CDProgram.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "isActive", ascending: false),
            NSSortDescriptor(key: "updatedAt", ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch cached programs: \(error)")
            return []
        }
    }

    /// Fetch the active program
    func fetchCachedActiveProgram() -> CDProgram? {
        let request: NSFetchRequest<CDProgram> = CDProgram.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Failed to fetch active program: \(error)")
            return nil
        }
    }

    /// Fetch a single cached program by server ID
    func fetchCachedProgram(serverId: String) -> CDProgram? {
        let request: NSFetchRequest<CDProgram> = CDProgram.fetchRequest()
        request.predicate = NSPredicate(format: "serverId == %@", serverId)
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Failed to fetch cached program: \(error)")
            return nil
        }
    }

    /// Fetch programs pending sync
    func fetchPendingPrograms() -> [CDProgram] {
        let request: NSFetchRequest<CDProgram> = CDProgram.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus != %d", 2) // Not synced
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch pending programs: \(error)")
            return []
        }
    }

    // MARK: - Save Operations

    /// Cache a program from domain model
    func cacheProgram(_ program: Program) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                do {
                    // Check if program already exists
                    let request: NSFetchRequest<CDProgram> = CDProgram.fetchRequest()
                    request.predicate = NSPredicate(format: "serverId == %@", program.serverId)
                    request.fetchLimit = 1

                    let existing = try context.fetch(request).first
                    let cdProgram = existing ?? CDProgram(context: context)

                    cdProgram.id = existing?.id ?? program.id
                    cdProgram.serverId = program.serverId
                    cdProgram.name = program.name
                    cdProgram.descriptionText = program.description
                    cdProgram.daysPerWeek = Int16(program.daysPerWeek)
                    cdProgram.durationWeeks = Int16(program.durationWeeks ?? 0)
                    cdProgram.isActive = program.isActive
                    cdProgram.currentDayIndex = Int16(program.currentDayIndex)
                    cdProgram.timesCompleted = Int32(program.timesCompleted)
                    cdProgram.isPublic = program.isPublic
                    cdProgram.isAiGenerated = program.isAiGenerated
                    cdProgram.createdAt = program.createdAt
                    cdProgram.updatedAt = program.updatedAt
                    cdProgram.lastFetchedAt = Date()
                    cdProgram.syncStatus = program.serverId.isEmpty ? 0 : 2 // unsynced if no serverId

                    // Only replace workouts when the incoming program actually has them.
                    // List endpoints may omit workouts — preserve cached data.
                    if !program.workouts.isEmpty {
                        if let existingWorkouts = cdProgram.workouts {
                            for case let workout as CDProgramWorkout in existingWorkouts {
                                context.delete(workout)
                            }
                        }

                        let orderedWorkouts = NSMutableOrderedSet()
                        for programWorkout in program.workouts {
                            let cdWorkout = CDProgramWorkout(context: context)
                            cdWorkout.id = programWorkout.id
                            cdWorkout.serverId = programWorkout.serverId
                            cdWorkout.dayNumber = Int16(programWorkout.dayNumber)
                            cdWorkout.dayLabel = programWorkout.dayLabel
                            cdWorkout.templateServerId = programWorkout.templateServerId
                            cdWorkout.program = cdProgram
                            orderedWorkouts.add(cdWorkout)
                        }
                        cdProgram.workouts = orderedWorkouts
                    }

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Set a program as active (deactivates others)
    func setActiveProgram(serverId: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                do {
                    // Deactivate all programs first
                    let allRequest: NSFetchRequest<CDProgram> = CDProgram.fetchRequest()
                    allRequest.predicate = NSPredicate(format: "isActive == YES")
                    let activePrograms = try context.fetch(allRequest)
                    for program in activePrograms {
                        program.isActive = false
                    }

                    // Activate the target program
                    let request: NSFetchRequest<CDProgram> = CDProgram.fetchRequest()
                    request.predicate = NSPredicate(format: "serverId == %@", serverId)
                    request.fetchLimit = 1

                    if let program = try context.fetch(request).first {
                        program.isActive = true
                    }

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Deactivate the current program
    func deactivateProgram(serverId: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<CDProgram> = CDProgram.fetchRequest()
                request.predicate = NSPredicate(format: "serverId == %@", serverId)
                request.fetchLimit = 1

                do {
                    if let program = try context.fetch(request).first {
                        program.isActive = false
                    }
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Update program progress
    func updateProgramProgress(serverId: String, currentDayIndex: Int, timesCompleted: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<CDProgram> = CDProgram.fetchRequest()
                request.predicate = NSPredicate(format: "serverId == %@", serverId)
                request.fetchLimit = 1

                do {
                    if let program = try context.fetch(request).first {
                        program.currentDayIndex = Int16(currentDayIndex)
                        program.timesCompleted = Int32(timesCompleted)
                        program.updatedAt = Date()
                    }
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Delete a cached program
    func deleteCachedProgram(serverId: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<CDProgram> = CDProgram.fetchRequest()
                request.predicate = NSPredicate(format: "serverId == %@", serverId)

                do {
                    let programs = try context.fetch(request)
                    for program in programs {
                        context.delete(program)
                    }
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Mark program as synced
    func markProgramSynced(serverId: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<CDProgram> = CDProgram.fetchRequest()
                request.predicate = NSPredicate(format: "serverId == %@", serverId)
                request.fetchLimit = 1

                do {
                    if let program = try context.fetch(request).first {
                        program.syncStatus = 2 // synced
                    }
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Clear program cache
    func clearProgramCache() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<CDProgram> = CDProgram.fetchRequest()

                do {
                    let programs = try context.fetch(request)
                    for program in programs {
                        context.delete(program)
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
    func toDomain(_ cdProgram: CDProgram) -> Program {
        let workouts = cdProgram.workoutsArray
            .sorted { $0.dayNumber < $1.dayNumber }
            .map { toDomain($0) }

        return Program(
            id: cdProgram.id ?? UUID(),
            serverId: cdProgram.serverId ?? "",
            name: cdProgram.name ?? "",
            description: cdProgram.descriptionText,
            daysPerWeek: Int(cdProgram.daysPerWeek),
            durationWeeks: cdProgram.durationWeeks > 0 ? Int(cdProgram.durationWeeks) : nil,
            workouts: workouts,
            isActive: cdProgram.isActive,
            currentDayIndex: Int(cdProgram.currentDayIndex),
            timesCompleted: Int(cdProgram.timesCompleted),
            isPublic: cdProgram.isPublic,
            isAiGenerated: cdProgram.isAiGenerated,
            createdAt: cdProgram.createdAt ?? Date(),
            updatedAt: cdProgram.updatedAt ?? Date(),
            lastFetchedAt: cdProgram.lastFetchedAt
        )
    }

    /// Convert program workout to domain model
    func toDomain(_ cdWorkout: CDProgramWorkout) -> ProgramWorkout {
        // Try to get template from cache
        var template: Template?
        if let templateId = cdWorkout.templateServerId,
           let cachedTemplate = fetchCachedTemplate(serverId: templateId) {
            template = toDomain(cachedTemplate)
        }

        return ProgramWorkout(
            id: cdWorkout.id ?? UUID(),
            serverId: cdWorkout.serverId ?? "",
            dayNumber: Int(cdWorkout.dayNumber),
            dayLabel: cdWorkout.dayLabel,
            templateServerId: cdWorkout.templateServerId ?? "",
            template: template
        )
    }
}
