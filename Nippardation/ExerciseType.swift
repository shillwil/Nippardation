//
//  ExerciseType.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//

import Foundation

struct ExerciseType: Hashable {
    var name: String
    var muscleGroup: [MuscleGroup]
    var dayAssociation: [Day]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(muscleGroup)
        hasher.combine(dayAssociation)
    }
    
    static func == (lhs: ExerciseType, rhs: ExerciseType) -> Bool {
        return lhs.name == rhs.name &&
               lhs.muscleGroup == rhs.muscleGroup &&
               lhs.dayAssociation == rhs.dayAssociation
    }
}
