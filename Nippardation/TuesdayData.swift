//
//  TuesdayData.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//

import Foundation

let tuesdayWorkout = Workout(
    name: "Lower (Strength Focus)",
    day: .tuesday,
    exercises: [
        Exercise(
            type: ExerciseType(name: "Lying Leg Curl", muscleGroup: [.hamstrings], dayAssociation: [.tuesday]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/sX4tGtcc62k?si=fVHTZ05sI-d-zT21" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 8...10,
            rest: 1...2,
            trackedSets: []
        ),
        Exercise(
            type: ExerciseType(name: "Smith Machine Squat", muscleGroup: [.quads, .hamstrings], dayAssociation: [.tuesday]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/J2D2J7RO_tA?si=sOl7cZFK4YgLeiPI" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 3,
            workingSets: 3,
            reps: 6...8,
            rest: 3...5,
            trackedSets: []
        ),
        Exercise(
            type: ExerciseType(name: "Barbell RDL", muscleGroup: [.back, .hamstrings], dayAssociation: [.tuesday]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/3fJwfg51cv0?si=Y6L1_kLAZAYS0n9M" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 3,
            workingSets: 3,
            reps: 6...8,
            rest: 2...3,
            trackedSets: []
        ),
        Exercise(
            type: ExerciseType(name: "Leg Extension", muscleGroup: [.quads], dayAssociation: [.tuesday]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/uFbNtqP966A?si=toFXBY4ADpP5fRrF" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 8...10,
            rest: 1...2,
            trackedSets: []
        ),
        Exercise(
            type: ExerciseType(name: "Standing Calf Raise", muscleGroup: [.calves], dayAssociation: [.tuesday]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/6lR2JdxUh7w?si=f3x1rHVJhPKS-G8g" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Static Stretch",
            warmUpSets: 2,
            workingSets: 2,
            reps: 6...8,
            rest: 1...2,
            trackedSets: []
        ),
        Exercise(
            type: ExerciseType(name: "Cable Crunch", muscleGroup: [.abs], dayAssociation: [.tuesday]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/epBrpaGHMcg?si=SiKwGX13GWWPo9w8" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 1,
            workingSets: 2,
            reps: 8...10,
            rest: 1...2,
            trackedSets: []
        ),
    ]
)
