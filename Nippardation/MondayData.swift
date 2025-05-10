//
//  MondayData.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//

import Foundation
let mondayWorkout = Workout(
    name: "Upper (Strength Focus)",
    day: .monday,
    exercises: [
        Exercise(
            type:ExerciseType(name: "45° Incline Barbell Press", muscleGroup: [.chest, .shoulders], dayAssociation: [.monday]),
            example: """
            <iframe width="560" height="315" src="https://www.youtube.com/embed/vqQ9ok0dEgk?si=h5RT_5Iq8jg29b2D" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
            """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 6...8,
            rest: 3...5,
        ),
        Exercise(
            type: ExerciseType(name: "Cable Crossover Ladder", muscleGroup: [.chest], dayAssociation: [.monday]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/0TP9kVcWGic?si=xUA3UanpDaHg9p9m" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 8...10,
            rest: 1...2,
        ),
        Exercise(
            type: ExerciseType(name: "Wide Grip Pull-Up", muscleGroup: [.back], dayAssociation: [.monday]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/yGnp0HU8BnA?si=C0iHZeeYgR0yKmjL" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 3,
            reps: 8...10,
            rest: 2...3,
        ),
        Exercise(
            type: ExerciseType(name: "High-Cable Lateral Raise", muscleGroup: [.shoulders], dayAssociation: [.monday]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/MnMux3Wc0Ac?si=4fQviaEb6hCYb9z2" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 8...10,
            rest: 1...2,
        ),
        Exercise(
            type: ExerciseType(name: "Pendlay Deficit Row", muscleGroup: [.back, .biceps], dayAssociation: [.monday]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/MmuyHKYCLps?si=wWuKCrEv7pI3VZko" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure + LLPs (extended set)",
            warmUpSets: 2,
            workingSets: 2,
            reps: 6...8,
            rest: 2...3,
        ),
        Exercise(
            type: ExerciseType(name: "Overhead Cable Triceps Extension", muscleGroup: [.triceps], dayAssociation: [.monday]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/9_I1PqZAjdA?si=jpFxCr-4KML69YDq" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 1,
            workingSets: 2,
            reps: 8...10,
            rest: 1...2,
        ),
        Exercise(
            type: ExerciseType(name: "Bayesian Cable Curl", muscleGroup: [.biceps], dayAssociation: [.monday]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/CWH5J_7kzjM?si=i3X8bMnji-HvKwnQ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 1,
            workingSets: 2,
            reps: 8...10,
            rest: 1...2,
        ),
    ]
)
