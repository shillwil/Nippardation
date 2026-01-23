//
//  CDTemplateExercise.swift
//  Nippardation
//
//  Core Data entity for exercises within templates
//

import Foundation
import CoreData

@objc(CDTemplateExercise)
public class CDTemplateExercise: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var serverId: String?
    @NSManaged public var exerciseServerId: String?
    @NSManaged public var orderIndex: Int16
    @NSManaged public var warmupSets: Int16
    @NSManaged public var workingSets: Int16
    @NSManaged public var targetReps: String?
    @NSManaged public var restSeconds: Int16
    @NSManaged public var notes: String?
    @NSManaged public var template: CDTemplate?
}

extension CDTemplateExercise {
    static func fetchRequest() -> NSFetchRequest<CDTemplateExercise> {
        return NSFetchRequest<CDTemplateExercise>(entityName: "CDTemplateExercise")
    }
}
