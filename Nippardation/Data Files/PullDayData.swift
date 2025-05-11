//
//  PullDayData.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/10/25.
//

import Foundation

let pullDay = Workout(
    name: "Pull Day (Hypertrophy Focus)",
    exercises: [
        Exercise(
            type: ExerciseType(name: "Neutral-Grip Lat Pulldown", muscleGroup: [.back, .biceps]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/lA4_1F9EAFU?si=JAXu1PN9aTqcV3-c" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 8...10,
            rest: 2...3
        ),
        Exercise(
            type: ExerciseType(name: "Chest-Supported Machine Row", muscleGroup: [.back]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/ijsSiWSzYw0?si=NV23jXiPY1kp6E8p" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 3,
            reps: 8...10,
            rest: 2...3
        ),
        Exercise(
            type: ExerciseType(name: "Neutral-Grip Seated Cable Row", muscleGroup: [.back]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/hM7XHxQgvLk?si=hVHuVuYRsGRx0yOO" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure + LLPs (Extended set)",
            warmUpSets: 2,
            workingSets: 2,
            reps: 10...12,
            rest: 2...3
        ),
        Exercise(
            type: ExerciseType(name: "1-Arm 45° Cable Rear Delt Flye", muscleGroup: [.shoulders]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/6G5DmVaocGM?si=G8qXJKX7y02FchmI" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Myo-Reps",
            warmUpSets: 2,
            workingSets: 2,
            reps: 10...12,
            rest: 1...2
        ),
        Exercise(
            type: ExerciseType(name: "Machine Shrug", muscleGroup: [.shoulders]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/ua0XuKwKQ9M?si=95puPAmEvsRyDeZo" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 2,
            workingSets: 2,
            reps: 10...12,
            rest: 1...2
        ),
        Exercise(
            type: ExerciseType(name: "EZ-Bar Cable Curl", muscleGroup: [.biceps]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/ck1zjNTnFew?si=ioE3liIQQJwjuF3O" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Failure",
            warmUpSets: 1,
            workingSets: 2,
            reps: 10...12,
            rest: 1...2
        ),
        Exercise(
            type: ExerciseType(name: "Machine Preacher Curl", muscleGroup: [.biceps]),
            example: """
                    <iframe width="560" height="315" src="https://www.youtube.com/embed/R2iUnBxFtis?si=Bs3S_zm71hvG9eyx" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                    """,
            lastSetIntensityTechnique: "Myo-Reps",
            warmUpSets: 1,
            workingSets: 2,
            reps: 12...15,
            rest: 1...2
        ),
    ])
