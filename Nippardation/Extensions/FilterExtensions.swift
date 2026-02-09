//
//  FilterExtensions.swift
//  Nippardation
//
//  Extensions for filter types used in exercise browsing
//

import Foundation

// MARK: - ExerciseFilter Extensions

extension ExerciseFilter {

    /// Returns the count of active filters applied
    var activeFilterCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        count += muscleGroups.count
        count += equipment.count
        if difficulty != nil { count += 1 }
        if movementPattern != nil { count += 1 }
        if exerciseType != nil { count += 1 }
        return count
    }

    /// Returns true if filters beyond muscle groups are active
    var hasNonMuscleFilters: Bool {
        !equipment.isEmpty || difficulty != nil || movementPattern != nil || exerciseType != nil
    }

    /// Creates a copy with the search text updated
    func withSearchText(_ text: String) -> ExerciseFilter {
        var copy = self
        copy.searchText = text
        return copy
    }

    /// Creates a copy with the muscle group toggled
    func togglingMuscleGroup(_ group: MuscleGroup) -> ExerciseFilter {
        var copy = self
        if copy.muscleGroups.contains(group) {
            copy.muscleGroups.remove(group)
        } else {
            copy.muscleGroups.insert(group)
        }
        return copy
    }

    /// Creates a copy with the equipment toggled
    func togglingEquipment(_ equip: Equipment) -> ExerciseFilter {
        var copy = self
        if copy.equipment.contains(equip) {
            copy.equipment.remove(equip)
        } else {
            copy.equipment.insert(equip)
        }
        return copy
    }
}

// MARK: - ExerciseFilters (API) Extensions

extension ExerciseFilters {

    /// Returns true if no filters are applied
    var isEmpty: Bool {
        muscleGroups.isEmpty &&
        equipment.isEmpty &&
        difficulties.isEmpty &&
        movementPatterns.isEmpty &&
        exerciseTypes.isEmpty &&
        searchQuery.isEmpty
    }

    /// Returns the count of active filters applied
    var activeFilterCount: Int {
        var count = 0
        if !searchQuery.isEmpty { count += 1 }
        count += muscleGroups.count
        count += equipment.count
        count += difficulties.count
        count += movementPatterns.count
        count += exerciseTypes.count
        return count
    }

    /// Creates a copy with the search query updated
    func withSearchQuery(_ query: String) -> ExerciseFilters {
        ExerciseFilters(
            muscleGroups: muscleGroups,
            equipment: equipment,
            difficulties: difficulties,
            movementPatterns: movementPatterns,
            exerciseTypes: exerciseTypes,
            searchQuery: query,
            includePrimaryOnly: includePrimaryOnly
        )
    }

    /// Creates an empty filter set
    static var empty: ExerciseFilters {
        ExerciseFilters()
    }
}

// MARK: - FilterOptionDTO Extensions

extension FilterOptionDTO: Identifiable {
    var id: String { value }
}

// MARK: - ExerciseFilterOptionsDTO Extensions

extension ExerciseFilterOptionsDTO {

    /// Creates an empty filter options object
    static var empty: ExerciseFilterOptionsDTO {
        ExerciseFilterOptionsDTO(
            muscleGroups: [],
            difficulties: [],
            equipment: [],
            movementPatterns: [],
            exerciseTypes: []
        )
    }
}

// MARK: - Conversion Helpers

extension ExerciseFilter {

    /// Converts domain filter to API filter format
    func toAPIFilters() -> ExerciseFilters {
        ExerciseFilters(
            muscleGroups: Set(muscleGroups.map { $0.rawValue }),
            equipment: Set(equipment.map { $0.rawValue }),
            difficulties: difficulty.map { Set([$0.rawValue]) } ?? [],
            movementPatterns: movementPattern.map { Set([$0.rawValue]) } ?? [],
            exerciseTypes: exerciseType.map { Set([$0.rawValue]) } ?? [],
            searchQuery: searchText,
            includePrimaryOnly: false
        )
    }
}
