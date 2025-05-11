import Foundation
import CoreData

@objc(CDTrackedExercise)
public class CDTrackedExercise: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var exerciseName: String?
    @NSManaged public var muscleGroups: [String]?
    @NSManaged public var workout: CDTrackedWorkout?
    @NSManaged public var trackedSets: NSSet?
}

// MARK: - Generated accessors for trackedSets
extension CDTrackedExercise {
    @objc(addTrackedSetsObject:)
    @NSManaged public func addToTrackedSets(_ value: CDTrackedSet)
    
    @objc(removeTrackedSetsObject:)
    @NSManaged public func removeFromTrackedSets(_ value: CDTrackedSet)
    
    @objc(addTrackedSets:)
    @NSManaged public func addToTrackedSets(_ values: NSSet)
    
    @objc(removeTrackedSets:)
    @NSManaged public func removeFromTrackedSets(_ values: NSSet)
    
    static func fetchRequest() -> NSFetchRequest<CDTrackedExercise> {
        return NSFetchRequest<CDTrackedExercise>(entityName: "CDTrackedExercise")
    }
}

// MARK: - Convenience methods
extension CDTrackedExercise {
    var trackedSetsArray: [CDTrackedSet] {
        let set = trackedSets ?? NSSet()
        return set.allObjects as? [CDTrackedSet] ?? []
    }
}
