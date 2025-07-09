//
//  IdentifiableIndex.swift
//  Nippardation
//
//  Created by Claude on 7/9/25.
//

import Foundation
// TODO: This is over-engineered, just have Int conform to identifiable with the provided code below. Not doing it tonight because it's late and Claude Code threw this IdentifiableIndex in the ActiveWorkoutView and ExercisesListView
struct IdentifiableIndex: Identifiable {
    let id: Int
    var value: Int { id }
}

//extension Int: Identifiable {
//    public var id: Int { self }
//}
