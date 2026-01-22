//
//  CoreDataManager+Templates.swift
//  Nippardation
//
//  Extension for template cache operations
//

import Foundation
import CoreData

// MARK: - Template Operations

extension CoreDataManager {

    // MARK: - Fetch Operations

    /// Fetch all cached templates
    func fetchCachedTemplates() -> [CDTemplate] {
        let request: NSFetchRequest<CDTemplate> = CDTemplate.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch cached templates: \(error)")
            return []
        }
    }

    /// Fetch a single cached template by server ID
    func fetchCachedTemplate(serverId: String) -> CDTemplate? {
        let request: NSFetchRequest<CDTemplate> = CDTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "serverId == %@", serverId)
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Failed to fetch cached template: \(error)")
            return nil
        }
    }

    /// Fetch templates pending sync
    func fetchPendingTemplates() -> [CDTemplate] {
        let request: NSFetchRequest<CDTemplate> = CDTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus != %d", 2) // Not synced
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch pending templates: \(error)")
            return []
        }
    }

    // MARK: - Save Operations

    /// Cache a template from domain model
    func cacheTemplate(_ template: Template) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                do {
                    // Check if template already exists
                    let request: NSFetchRequest<CDTemplate> = CDTemplate.fetchRequest()
                    request.predicate = NSPredicate(format: "serverId == %@", template.serverId)
                    request.fetchLimit = 1

                    let existing = try context.fetch(request).first
                    let cdTemplate = existing ?? CDTemplate(context: context)

                    cdTemplate.id = existing?.id ?? template.id
                    cdTemplate.serverId = template.serverId
                    cdTemplate.name = template.name
                    cdTemplate.descriptionText = template.description
                    cdTemplate.isPublic = template.isPublic
                    cdTemplate.isAiGenerated = template.isAiGenerated
                    cdTemplate.createdAt = template.createdAt
                    cdTemplate.updatedAt = template.updatedAt
                    cdTemplate.lastFetchedAt = Date()
                    cdTemplate.syncStatus = template.serverId.isEmpty ? 0 : 2 // unsynced if no serverId

                    // Remove existing exercises and add new ones
                    if let existingExercises = cdTemplate.exercises {
                        for case let exercise as CDTemplateExercise in existingExercises {
                            context.delete(exercise)
                        }
                    }

                    // Add exercises
                    let orderedExercises = NSMutableOrderedSet()
                    for templateExercise in template.exercises {
                        let cdExercise = CDTemplateExercise(context: context)
                        cdExercise.id = templateExercise.id
                        cdExercise.serverId = templateExercise.serverId
                        cdExercise.exerciseServerId = templateExercise.exerciseServerId
                        cdExercise.orderIndex = Int16(templateExercise.orderIndex)
                        cdExercise.warmupSets = Int16(templateExercise.warmupSets ?? 0)
                        cdExercise.workingSets = Int16(templateExercise.workingSets)
                        cdExercise.targetReps = templateExercise.targetReps
                        cdExercise.restSeconds = Int16(templateExercise.restSeconds ?? 0)
                        cdExercise.notes = templateExercise.notes
                        cdExercise.template = cdTemplate
                        orderedExercises.add(cdExercise)
                    }
                    cdTemplate.exercises = orderedExercises

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Cache multiple templates
    func cacheTemplates(_ templates: [Template]) async throws {
        for template in templates {
            try await cacheTemplate(template)
        }
    }

    /// Delete a cached template
    func deleteCachedTemplate(serverId: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<CDTemplate> = CDTemplate.fetchRequest()
                request.predicate = NSPredicate(format: "serverId == %@", serverId)

                do {
                    let templates = try context.fetch(request)
                    for template in templates {
                        context.delete(template)
                    }
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Mark template as synced
    func markTemplateSynced(serverId: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<CDTemplate> = CDTemplate.fetchRequest()
                request.predicate = NSPredicate(format: "serverId == %@", serverId)
                request.fetchLimit = 1

                do {
                    if let template = try context.fetch(request).first {
                        template.syncStatus = 2 // synced
                    }
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Clear template cache
    func clearTemplateCache() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<CDTemplate> = CDTemplate.fetchRequest()

                do {
                    let templates = try context.fetch(request)
                    for template in templates {
                        context.delete(template)
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
    func toDomain(_ cdTemplate: CDTemplate) -> Template {
        let exercises = cdTemplate.exercisesArray
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { toDomain($0) }

        return Template(
            id: cdTemplate.id ?? UUID(),
            serverId: cdTemplate.serverId ?? "",
            name: cdTemplate.name ?? "",
            description: cdTemplate.descriptionText,
            exercises: exercises,
            isPublic: cdTemplate.isPublic,
            isAiGenerated: cdTemplate.isAiGenerated,
            createdAt: cdTemplate.createdAt ?? Date(),
            updatedAt: cdTemplate.updatedAt ?? Date(),
            lastFetchedAt: cdTemplate.lastFetchedAt
        )
    }

    /// Convert template exercise to domain model
    func toDomain(_ cdExercise: CDTemplateExercise) -> TemplateExercise {
        // Try to get the full exercise from cache
        var exerciseLibraryItem: ExerciseLibraryItem?
        if let serverId = cdExercise.exerciseServerId,
           let cachedExercise = fetchCachedExercise(serverId: serverId) {
            exerciseLibraryItem = toDomain(cachedExercise)
        }

        return TemplateExercise(
            id: cdExercise.id ?? UUID(),
            serverId: cdExercise.serverId ?? "",
            exerciseServerId: cdExercise.exerciseServerId ?? "",
            exerciseLibraryItem: exerciseLibraryItem,
            orderIndex: Int(cdExercise.orderIndex),
            warmupSets: cdExercise.warmupSets > 0 ? Int(cdExercise.warmupSets) : nil,
            workingSets: Int(cdExercise.workingSets),
            targetReps: cdExercise.targetReps,
            restSeconds: cdExercise.restSeconds > 0 ? Int(cdExercise.restSeconds) : nil,
            notes: cdExercise.notes
        )
    }
}
