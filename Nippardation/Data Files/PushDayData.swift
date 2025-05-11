//
//  PushDayData.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/10/25.
//

import Foundation

let pushDay = Workout(
    name: "Push Day (Hypertrophy Focus)",
    exercises: [
        Exercise(
            type: ExerciseType(name: "Barbell Bench Press", muscleGroup: [.chest]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/nQL5ieH39sw?si=rfq23vZUMl1A7gFP" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 3,
            reps: 8...10,
            rest: 3...5
        ),
        Exercise(
            type: ExerciseType(name: "Machine Shoulder Press", muscleGroup: [.shoulders]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/SCQVmN1gYsk?si=Xd53S1RKv8m9fVzN" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 8...10,
            rest: 2...3
        ),
        Exercise(
            type: ExerciseType(name: "Bottom-Half DB Flye", muscleGroup: [.chest]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/qJzc-iHKGdg?si=s4lY3g4n1qsVtsKD" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 10...12,
            rest: 1...2
        ),
        Exercise(
            type: ExerciseType(name: "High-Cable Lateral Raise", muscleGroup: [.shoulders]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/MnMux3Wc0Ac?si=_mbDwavkZclCjLmb" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Myo-Reps",
            warmUpSets: 1,
            workingSets: 2,
            reps: 10...12,
            rest: 1...2
        ),
        Exercise(
            type: ExerciseType(name: "Overhead Cable Triceps Extension", muscleGroup: [.triceps]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/9_I1PqZAjdA?si=QwhLqatnevuV86gl" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 1,
            workingSets: 2,
            reps: 10...12,
            rest: 1...2
        ),
        Exercise(
            type: ExerciseType(name: "Cable Triceps Kickback", muscleGroup: [.triceps]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/oRxTKRtP8RE?si=A_kZ8ThncL8eLEfE" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Myo-Reps",
            warmUpSets: 1,
            workingSets: 2,
            reps: 12...15,
            rest: 1...2
        ),
        Exercise(
            type: ExerciseType(name: "Roman Chair Leg Raise", muscleGroup: [.abs]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/irOzFVqJ0IE?si=mXKKq1JNALyPbx4r" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 10...20,
            rest: 1...2
        ),
    ]
)
