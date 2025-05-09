//
//  HomeViewModel.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//

import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @State var workouts: [Workout] = [
        mondayWorkout,
        tuesdayWorkout
    ]
}
