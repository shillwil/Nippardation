//
//  Workout.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import Foundation

struct Workout: Hashable, Identifiable {
    var id = UUID()
    var name: String
    var day: Day
    var exercises: [Exercise]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(id)
    }
    
    static func == (lhs: Workout, rhs: Workout) -> Bool {
        return lhs.name == rhs.name &&
        lhs.id == rhs.id
    }
}
