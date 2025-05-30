//
//  Exercise.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import Foundation

struct Exercise: Identifiable {
    var id = UUID()
    var type: ExerciseType
    var example: String
    var lastSetIntensityTechnique: String
    var warmUpSets: Int
    var workingSets: Int
    var reps: ClosedRange<Int>
    var rest: ClosedRange<Int>
}
