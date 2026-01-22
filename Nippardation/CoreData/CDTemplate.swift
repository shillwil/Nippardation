//
//  CDTemplate.swift
//  Nippardation
//
//  Core Data entity for cached workout templates
//

import Foundation
import CoreData

@objc(CDTemplate)
public class CDTemplate: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var serverId: String?
    @NSManaged public var name: String?
    @NSManaged public var descriptionText: String?
    @NSManaged public var isPublic: Bool
    @NSManaged public var isAiGenerated: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastFetchedAt: Date?
    @NSManaged public var syncStatus: Int16  // 0=unsynced, 1=syncing, 2=synced
    @NSManaged public var exercises: NSOrderedSet?
}

// MARK: - Generated accessors for exercises

extension CDTemplate {
    @objc(insertObject:inExercisesAtIndex:)
    @NSManaged public func insertIntoExercises(_ value: CDTemplateExercise, at idx: Int)

    @objc(removeObjectFromExercisesAtIndex:)
    @NSManaged public func removeFromExercises(at idx: Int)

    @objc(insertExercises:atIndexes:)
    @NSManaged public func insertIntoExercises(_ values: [CDTemplateExercise], at indexes: NSIndexSet)

    @objc(removeExercisesAtIndexes:)
    @NSManaged public func removeFromExercises(at indexes: NSIndexSet)

    @objc(replaceObjectInExercisesAtIndex:withObject:)
    @NSManaged public func replaceExercises(at idx: Int, with value: CDTemplateExercise)

    @objc(replaceExercisesAtIndexes:withExercises:)
    @NSManaged public func replaceExercises(at indexes: NSIndexSet, with values: [CDTemplateExercise])

    @objc(addExercisesObject:)
    @NSManaged public func addToExercises(_ value: CDTemplateExercise)

    @objc(removeExercisesObject:)
    @NSManaged public func removeFromExercises(_ value: CDTemplateExercise)

    @objc(addExercises:)
    @NSManaged public func addToExercises(_ values: NSOrderedSet)

    @objc(removeExercises:)
    @NSManaged public func removeFromExercises(_ values: NSOrderedSet)

    static func fetchRequest() -> NSFetchRequest<CDTemplate> {
        return NSFetchRequest<CDTemplate>(entityName: "CDTemplate")
    }
}

// MARK: - Convenience Methods

extension CDTemplate {
    /// Exercises as Swift array, ordered by orderIndex
    var exercisesArray: [CDTemplateExercise] {
        return exercises?.array as? [CDTemplateExercise] ?? []
    }
}
