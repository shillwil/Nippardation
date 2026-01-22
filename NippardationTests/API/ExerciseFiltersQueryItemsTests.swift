//
//  ExerciseFiltersQueryItemsTests.swift
//  NippardationTests
//
//  Tests for ExerciseFilters+QueryItems extension
//

import Testing
import Foundation
@testable import Nippardation

struct ExerciseFiltersQueryItemsTests {

    // MARK: - Empty Filters

    @Test func emptyFiltersProducesNoQueryItems() {
        let filters = ExerciseFilters()
        let queryItems = filters.toQueryItems()

        #expect(queryItems.isEmpty)
    }

    // MARK: - Muscle Groups

    @Test func singleMuscleGroupProducesCorrectQueryItem() {
        let filters = ExerciseFilters(muscleGroups: ["chest"])
        let queryItems = filters.toQueryItems()

        #expect(queryItems.count == 1)
        #expect(queryItems[0].name == "muscle_groups[]")
        #expect(queryItems[0].value == "chest")
    }

    @Test func multipleMuscleGroupsProduceMultipleQueryItems() {
        let filters = ExerciseFilters(muscleGroups: ["chest", "back", "shoulders"])
        let queryItems = filters.toQueryItems()

        let muscleItems = queryItems.filter { $0.name == "muscle_groups[]" }
        #expect(muscleItems.count == 3)

        let values = Set(muscleItems.compactMap { $0.value })
        #expect(values.contains("chest"))
        #expect(values.contains("back"))
        #expect(values.contains("shoulders"))
    }

    // MARK: - Equipment

    @Test func singleEquipmentProducesCorrectQueryItem() {
        let filters = ExerciseFilters(equipment: ["barbell"])
        let queryItems = filters.toQueryItems()

        #expect(queryItems.count == 1)
        #expect(queryItems[0].name == "equipment[]")
        #expect(queryItems[0].value == "barbell")
    }

    @Test func multipleEquipmentProducesMultipleQueryItems() {
        let filters = ExerciseFilters(equipment: ["barbell", "dumbbell"])
        let queryItems = filters.toQueryItems()

        let equipmentItems = queryItems.filter { $0.name == "equipment[]" }
        #expect(equipmentItems.count == 2)
    }

    // MARK: - Difficulties

    @Test func singleDifficultyProducesCorrectQueryItem() {
        let filters = ExerciseFilters(difficulties: ["beginner"])
        let queryItems = filters.toQueryItems()

        #expect(queryItems.count == 1)
        #expect(queryItems[0].name == "difficulties[]")
        #expect(queryItems[0].value == "beginner")
    }

    // MARK: - Movement Patterns

    @Test func movementPatternsProduceCorrectQueryItems() {
        let filters = ExerciseFilters(movementPatterns: ["push", "pull"])
        let queryItems = filters.toQueryItems()

        let patternItems = queryItems.filter { $0.name == "movement_patterns[]" }
        #expect(patternItems.count == 2)
    }

    // MARK: - Exercise Types

    @Test func exerciseTypesProduceCorrectQueryItems() {
        let filters = ExerciseFilters(exerciseTypes: ["compound", "isolation"])
        let queryItems = filters.toQueryItems()

        let typeItems = queryItems.filter { $0.name == "exercise_types[]" }
        #expect(typeItems.count == 2)
    }

    // MARK: - Search Query

    @Test func emptySearchQueryProducesNoQueryItem() {
        let filters = ExerciseFilters(searchQuery: "")
        let queryItems = filters.toQueryItems()

        let searchItems = queryItems.filter { $0.name == "q" }
        #expect(searchItems.isEmpty)
    }

    @Test func nonEmptySearchQueryProducesQueryItem() {
        let filters = ExerciseFilters(searchQuery: "bench press")
        let queryItems = filters.toQueryItems()

        let searchItems = queryItems.filter { $0.name == "q" }
        #expect(searchItems.count == 1)
        #expect(searchItems[0].value == "bench press")
    }

    // MARK: - Include Primary Only

    @Test func includePrimaryOnlyFalseProducesNoQueryItem() {
        let filters = ExerciseFilters(includePrimaryOnly: false)
        let queryItems = filters.toQueryItems()

        let primaryItems = queryItems.filter { $0.name == "primary_only" }
        #expect(primaryItems.isEmpty)
    }

    @Test func includePrimaryOnlyTrueProducesQueryItem() {
        let filters = ExerciseFilters(includePrimaryOnly: true)
        let queryItems = filters.toQueryItems()

        let primaryItems = queryItems.filter { $0.name == "primary_only" }
        #expect(primaryItems.count == 1)
        #expect(primaryItems[0].value == "true")
    }

    // MARK: - Combined Filters

    @Test func combinedFiltersProduceAllQueryItems() {
        let filters = ExerciseFilters(
            muscleGroups: ["chest", "back"],
            equipment: ["barbell"],
            difficulties: ["intermediate"],
            movementPatterns: ["push"],
            exerciseTypes: ["compound"],
            searchQuery: "press",
            includePrimaryOnly: true
        )
        let queryItems = filters.toQueryItems()

        // 2 muscle groups + 1 equipment + 1 difficulty + 1 pattern + 1 type + 1 search + 1 primary = 8
        #expect(queryItems.count == 8)

        #expect(queryItems.filter { $0.name == "muscle_groups[]" }.count == 2)
        #expect(queryItems.filter { $0.name == "equipment[]" }.count == 1)
        #expect(queryItems.filter { $0.name == "difficulties[]" }.count == 1)
        #expect(queryItems.filter { $0.name == "movement_patterns[]" }.count == 1)
        #expect(queryItems.filter { $0.name == "exercise_types[]" }.count == 1)
        #expect(queryItems.filter { $0.name == "q" }.count == 1)
        #expect(queryItems.filter { $0.name == "primary_only" }.count == 1)
    }
}
