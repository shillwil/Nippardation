//
//  LegDayData.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/10/25.
//

import Foundation

let legDay = Workout(
    name: "Legs (Hypertrophy Focus)",
    exercises: [
        Exercise(
            type: ExerciseType(name: "Leg Press", muscleGroup: [.quads, .hamstrings]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/1yKAQLVV_XI?si=CLsViVtlGsK8iKZy" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 3,
            workingSets: 3,
            reps: 8...10,
            rest: 2...3
        ),
        Exercise(
            type: ExerciseType(name: "Seated Leg Curl", muscleGroup: [.hamstrings]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/yv0aAY7M1mk?si=iY6c773l9YnR-B1v" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure + LLPs (Extended set)",
            warmUpSets: 2,
            workingSets: 2,
            reps: 10...12,
            rest: 1...2
        ),
        Exercise(
            type: ExerciseType(name: "DB Bulgarian Split Squat", muscleGroup: [.glutes, .hamstrings, .quads]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/htDXu61MPio?si=A1LGE0ktwTaEmhxs" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 8...10,
            rest: 2...3
        ),
        Exercise(
            type: ExerciseType(name: "Leg Extension", muscleGroup: [.quads]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/uFbNtqP966A?si=7Z_m80yRZqJZzOx4" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Myo-Reps",
            warmUpSets: 2,
            workingSets: 2,
            reps: 10...12,
            rest: 1...2
        ),
        Exercise(
            type: ExerciseType(name: "Machine Hip-Adduction", muscleGroup: [.glutes]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/FMSCZYu1JhE?si=cLfDv23KS1QSAJlN" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 10...12,
            rest: 1...2
        ),
        Exercise(
            type: ExerciseType(name: "Machine Hip Abduction", muscleGroup: [.glutes]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/pozooPg6PBE?si=2pxVA_Ob0eCJqX3t" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 10...12,
            rest: 1...2
        ),
        Exercise(
            type: ExerciseType(name: "Standing Calf Raise", muscleGroup: [.calves]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/6lR2JdxUh7w?si=jsS89K2K1UXDZE5Y" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Static Stretch (30sec)",
            warmUpSets: 2,
            workingSets: 2,
            reps: 10...12,
            rest: 1...2
        ),
    ]
)
