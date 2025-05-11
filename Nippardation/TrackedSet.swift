//
//  TrackedSet.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import Foundation

struct TrackedSet: Hashable, Equatable, Identifiable {
    let id = UUID()
    var reps: Int
    var setType: SetType
    var exerciseType: ExerciseType
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(reps)
        hasher.combine(exerciseType)
    }
        
    static func == (lhs: TrackedSet, rhs: TrackedSet) -> Bool {
        return lhs.reps == rhs.reps && lhs.exerciseType == rhs.exerciseType
    }
}

enum SetType {
    case warmup
    case working
}
