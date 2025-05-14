//
//  TrackedExercise.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/11/25.
//

import Foundation

struct TrackedExercise: Identifiable, Codable {
    var id = UUID()
    var exerciseName: String
    var muscleGroups: [String]  // Store as strings for Codable compliance
    var trackedSets: [TrackedSet]
    
    var isCompleted: Bool {
        return !trackedSets.isEmpty
    }
}
