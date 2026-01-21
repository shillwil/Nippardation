import Foundation
import CoreData

@objc(CDTrackedWorkout)
public class CDTrackedWorkout: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var userID: String?
    @NSManaged public var date: Date?
    @NSManaged public var workoutTemplate: String?
    @NSManaged public var duration: Double
    @NSManaged public var isCompleted: Bool
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var trackedExercises: NSSet?

    // Sync attributes (added in v2)
    @NSManaged public var serverId: String?
    @NSManaged public var syncStatus: Int16  // 0=unsynced, 1=syncing, 2=synced
    @NSManaged public var templateServerId: String?
    @NSManaged public var lastSyncedAt: Date?
}

// MARK: - Generated accessors for trackedExercises
extension CDTrackedWorkout {
    @objc(addTrackedExercisesObject:)
    @NSManaged public func addToTrackedExercises(_ value: CDTrackedExercise)
    
    @objc(removeTrackedExercisesObject:)
    @NSManaged public func removeFromTrackedExercises(_ value: CDTrackedExercise)
    
    @objc(addTrackedExercises:)
    @NSManaged public func addToTrackedExercises(_ values: NSSet)
    
    @objc(removeTrackedExercises:)
    @NSManaged public func removeFromTrackedExercises(_ values: NSSet)
    
    static func fetchRequest() -> NSFetchRequest<CDTrackedWorkout> {
        return NSFetchRequest<CDTrackedWorkout>(entityName: "CDTrackedWorkout")
    }
}

// MARK: - Convenience methods
extension CDTrackedWorkout {
    var trackedExercisesArray: [CDTrackedExercise] {
        let set = trackedExercises ?? NSSet()
        return set.allObjects as? [CDTrackedExercise] ?? []
    }
}
