//
//  CoreDataTestHelper.swift
//  NippardationTests
//
//  Test helper for creating in-memory Core Data stacks
//

import Foundation
import CoreData
@testable import Nippardation

/// Test helper that provides an in-memory Core Data stack for testing
class CoreDataTestHelper {

    /// Creates a CoreDataManager configured for testing with in-memory store
    static func createInMemoryManager() -> CoreDataManager {
        let manager = TestCoreDataManager()
        return manager
    }

    /// Creates a sample ExerciseLibraryItem for testing
    static func createSampleExerciseLibraryItem(
        serverId: String = "exercise-1",
        name: String = "Bench Press",
        primaryMuscles: [MuscleGroup] = [.chest],
        secondaryMuscles: [MuscleGroup] = [.triceps, .shoulders],
        equipment: Equipment? = .barbell,
        difficulty: Difficulty? = .intermediate,
        popularityScore: Int = 100
    ) -> ExerciseLibraryItem {
        ExerciseLibraryItem(
            id: UUID(),
            serverId: serverId,
            name: name,
            primaryMuscles: primaryMuscles,
            secondaryMuscles: secondaryMuscles,
            equipment: equipment,
            difficulty: difficulty,
            movementPattern: .push,
            exerciseType: .compound,
            instructions: "Lie on bench, lower bar to chest, press up",
            videoUrl: URL(string: "https://example.com/video"),
            thumbnailUrl: URL(string: "https://example.com/thumb"),
            popularityScore: popularityScore,
            lastFetchedAt: Date()
        )
    }

    /// Creates a sample Template for testing
    static func createSampleTemplate(
        serverId: String = "template-1",
        name: String = "Push Day",
        exercises: [TemplateExercise] = []
    ) -> Template {
        Template(
            id: UUID(),
            serverId: serverId,
            name: name,
            description: "A push-focused workout",
            exercises: exercises,
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
    }

    /// Creates a sample TemplateExercise for testing
    static func createSampleTemplateExercise(
        serverId: String = "template-exercise-1",
        exerciseServerId: String = "exercise-1",
        orderIndex: Int = 0,
        warmupSets: Int = 2,
        workingSets: Int = 3
    ) -> TemplateExercise {
        TemplateExercise(
            id: UUID(),
            serverId: serverId,
            exerciseServerId: exerciseServerId,
            exerciseLibraryItem: nil,
            orderIndex: orderIndex,
            warmupSets: warmupSets,
            workingSets: workingSets,
            targetReps: "8-12",
            restSeconds: 90,
            notes: nil
        )
    }

    /// Creates a sample Program for testing
    static func createSampleProgram(
        serverId: String = "program-1",
        name: String = "PPL Program",
        daysPerWeek: Int = 6,
        isActive: Bool = false
    ) -> Program {
        Program(
            id: UUID(),
            serverId: serverId,
            name: name,
            description: "Push/Pull/Legs split",
            daysPerWeek: daysPerWeek,
            durationWeeks: 12,
            workouts: [],
            isActive: isActive,
            currentDayIndex: 0,
            timesCompleted: 0,
            isPublic: false,
            isAiGenerated: false,
            createdAt: Date(),
            updatedAt: Date(),
            lastFetchedAt: nil
        )
    }

    /// Creates a sample ProgramWorkout for testing
    static func createSampleProgramWorkout(
        serverId: String = "program-workout-1",
        dayNumber: Int = 1,
        templateServerId: String = "template-1"
    ) -> ProgramWorkout {
        ProgramWorkout(
            id: UUID(),
            serverId: serverId,
            dayNumber: dayNumber,
            dayLabel: "Day \(dayNumber)",
            templateServerId: templateServerId,
            template: nil
        )
    }

    /// Creates a sample TrackedWorkout for testing
    static func createSampleTrackedWorkout(
        workoutTemplate: String = "Push Day",
        isCompleted: Bool = true
    ) -> TrackedWorkout {
        let exercise = TrackedExercise(
            id: UUID(),
            exerciseName: "Bench Press",
            muscleGroups: ["chest", "triceps"],
            trackedSets: [
                TrackedSet(
                    reps: 10,
                    weight: 135,
                    setType: .working,
                    exerciseType: ExerciseType(name: "Bench Press", muscleGroup: [.chest])
                )
            ]
        )

        return TrackedWorkout(
            id: UUID(),
            userID: "test-user",
            date: Date(),
            workoutTemplate: workoutTemplate,
            duration: 3600,
            trackedExercises: [exercise],
            isCompleted: isCompleted,
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date()
        )
    }
}

/// Subclass of CoreDataManager that uses an in-memory store for testing
class TestCoreDataManager: CoreDataManager {

    override init() {
        super.init()
    }

    override lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CDModel")

        // Use in-memory store
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()
}
