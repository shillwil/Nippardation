//
//  TrackedWorkout.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/11/25.
//

import Foundation
struct TrackedWorkout: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var workoutTemplate: String  // Name of the template used
    var duration: TimeInterval?  // Duration in seconds
    var trackedExercises: [TrackedExercise]
    var isCompleted: Bool = false
    
    // For tracking workout progress
    var startTime: Date?
    var endTime: Date?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

extension TrackedWorkout: Equatable {
    static func == (lhs: TrackedWorkout, rhs: TrackedWorkout) -> Bool {
        lhs.id == rhs.id
    }
}

