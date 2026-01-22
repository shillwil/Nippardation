//
//  CDProgramWorkout.swift
//  Nippardation
//
//  Core Data entity for workouts within programs
//

import Foundation
import CoreData

@objc(CDProgramWorkout)
public class CDProgramWorkout: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var serverId: String?
    @NSManaged public var dayNumber: Int16
    @NSManaged public var dayLabel: String?
    @NSManaged public var templateServerId: String?
    @NSManaged public var program: CDProgram?
}

extension CDProgramWorkout {
    static func fetchRequest() -> NSFetchRequest<CDProgramWorkout> {
        return NSFetchRequest<CDProgramWorkout>(entityName: "CDProgramWorkout")
    }
}
