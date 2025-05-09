//
//  NippardationApp.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import SwiftUI

@main
struct NippardationApp: App {
    var body: some Scene {
        WindowGroup {
            ExerciseDetailView(exercise: .constant(Exercise(
                type: ExerciseType(name: "Neutral-Grip Lat Pulldown", muscleGroup: [.back, .biceps], dayAssociation: [.wednesday]),
                example: "https://www.youtube.com/watch?v=lA4_1F9EAFU",
                lastSetIntensityTechnique: "Failure",
                warmUpSets: 2,
                workingSets: 2,
                reps: 8...10,
                trackedSets: []
            )))
        }
    }
}
