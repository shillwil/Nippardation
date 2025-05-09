//
//  ExerciseViewModel.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//

import SwiftUI
import Combine

class ExerciseViewModel: ObservableObject {
    @Published var trackedSets: [TrackedSet] = []
        
        func addSet(_ set: TrackedSet) {
            trackedSets.append(set)
            print("Set added, total sets: \(trackedSets.count)")
        }
        
        func deleteSet(at offsets: IndexSet) {
            trackedSets.remove(atOffsets: offsets)
        }
        
        func updateSet(at index: Int, with newSet: TrackedSet) {
            guard index >= 0 && index < trackedSets.count else { return }
            trackedSets[index] = newSet
        }
}
