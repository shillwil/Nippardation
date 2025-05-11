//
//  CDTrackedSet.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/11/25.
//

import Foundation
import CoreData

@objc(CDTrackedSet)
public class CDTrackedSet: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var reps: Int16
    @NSManaged public var weight: Double  // Added weight property
    @NSManaged public var setType: Int16  // 0 = warmup, 1 = working
    @NSManaged public var exerciseTypeName: String?
    @NSManaged public var exerciseTypeMuscleGroups: [String]?
    @NSManaged public var exercise: CDTrackedExercise?
}

extension CDTrackedSet {
    static func fetchRequest() -> NSFetchRequest<CDTrackedSet> {
        return NSFetchRequest<CDTrackedSet>(entityName: "CDTrackedSet")
    }
}
