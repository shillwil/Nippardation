//
//  CDProgram.swift
//  Nippardation
//
//  Core Data entity for cached workout programs
//

import Foundation
import CoreData

@objc(CDProgram)
public class CDProgram: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var serverId: String?
    @NSManaged public var name: String?
    @NSManaged public var descriptionText: String?
    @NSManaged public var daysPerWeek: Int16
    @NSManaged public var durationWeeks: Int16  // 0 = indefinite
    @NSManaged public var isActive: Bool
    @NSManaged public var currentDayIndex: Int16
    @NSManaged public var timesCompleted: Int32
    @NSManaged public var isPublic: Bool
    @NSManaged public var isAiGenerated: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastFetchedAt: Date?
    @NSManaged public var syncStatus: Int16  // 0=unsynced, 1=syncing, 2=synced
    @NSManaged public var workouts: NSOrderedSet?
}

// MARK: - Generated accessors for workouts

extension CDProgram {
    @objc(insertObject:inWorkoutsAtIndex:)
    @NSManaged public func insertIntoWorkouts(_ value: CDProgramWorkout, at idx: Int)

    @objc(removeObjectFromWorkoutsAtIndex:)
    @NSManaged public func removeFromWorkouts(at idx: Int)

    @objc(insertWorkouts:atIndexes:)
    @NSManaged public func insertIntoWorkouts(_ values: [CDProgramWorkout], at indexes: NSIndexSet)

    @objc(removeWorkoutsAtIndexes:)
    @NSManaged public func removeFromWorkouts(at indexes: NSIndexSet)

    @objc(replaceObjectInWorkoutsAtIndex:withObject:)
    @NSManaged public func replaceWorkouts(at idx: Int, with value: CDProgramWorkout)

    @objc(replaceWorkoutsAtIndexes:withWorkouts:)
    @NSManaged public func replaceWorkouts(at indexes: NSIndexSet, with values: [CDProgramWorkout])

    @objc(addWorkoutsObject:)
    @NSManaged public func addToWorkouts(_ value: CDProgramWorkout)

    @objc(removeWorkoutsObject:)
    @NSManaged public func removeFromWorkouts(_ value: CDProgramWorkout)

    @objc(addWorkouts:)
    @NSManaged public func addToWorkouts(_ values: NSOrderedSet)

    @objc(removeWorkouts:)
    @NSManaged public func removeFromWorkouts(_ values: NSOrderedSet)

    static func fetchRequest() -> NSFetchRequest<CDProgram> {
        return NSFetchRequest<CDProgram>(entityName: "CDProgram")
    }
}

// MARK: - Convenience Methods

extension CDProgram {
    /// Workouts as Swift array, ordered by dayNumber
    var workoutsArray: [CDProgramWorkout] {
        return workouts?.array as? [CDProgramWorkout] ?? []
    }
}
