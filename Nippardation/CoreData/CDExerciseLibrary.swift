//
//  CDExerciseLibrary.swift
//  Nippardation
//
//  Core Data entity for cached exercise library items
//

import Foundation
import CoreData

@objc(CDExerciseLibrary)
public class CDExerciseLibrary: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var serverId: String?
    @NSManaged public var name: String?
    @NSManaged public var primaryMuscles: NSArray?
    @NSManaged public var secondaryMuscles: NSArray?
    @NSManaged public var equipment: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var movementPattern: String?
    @NSManaged public var exerciseType: String?
    @NSManaged public var instructions: String?
    @NSManaged public var videoUrl: String?
    @NSManaged public var thumbnailUrl: String?
    @NSManaged public var popularityScore: Int32
    @NSManaged public var lastFetchedAt: Date?
}

extension CDExerciseLibrary {
    static func fetchRequest() -> NSFetchRequest<CDExerciseLibrary> {
        return NSFetchRequest<CDExerciseLibrary>(entityName: "CDExerciseLibrary")
    }
}

// MARK: - Convenience Methods

extension CDExerciseLibrary {
    /// Primary muscles as Swift array
    var primaryMusclesArray: [String] {
        return primaryMuscles as? [String] ?? []
    }

    /// Secondary muscles as Swift array
    var secondaryMusclesArray: [String] {
        return secondaryMuscles as? [String] ?? []
    }
}
