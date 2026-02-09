//
//  ExerciseFilters+QueryItems.swift
//  Nippardation
//
//  Extension for converting ExerciseFilters to URL query items
//

import Foundation

extension ExerciseFilters {
    /// Convert filters to URL query items for API requests
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        for muscle in muscleGroups {
            items.append(URLQueryItem(name: "muscleGroup", value: muscle))
        }

        for equip in equipment {
            items.append(URLQueryItem(name: "equipment", value: equip))
        }

        for diff in difficulties {
            items.append(URLQueryItem(name: "difficulty", value: diff))
        }

        for pattern in movementPatterns {
            items.append(URLQueryItem(name: "movementPattern", value: pattern))
        }

        for type in exerciseTypes {
            items.append(URLQueryItem(name: "exerciseType", value: type))
        }

        if !searchQuery.isEmpty {
            items.append(URLQueryItem(name: "q", value: searchQuery))
        }

        if includePrimaryOnly {
            items.append(URLQueryItem(name: "primary_only", value: "true"))
        }

        return items
    }
}
