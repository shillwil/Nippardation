//
//  ContentView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import SwiftUI

struct ContentView: View {
    @State private var workoutDay: [String] = [
        "Upper (Strength Focus)",
        "Lower (Strength Focus)",
        "Pull (Hypertrophy Focus)",
        "Push (Hypertrophy Focus)",
        "Legs (Hypertrophy Focus)"
    ]
    @State private var generalInfo: [String] = [
        "Exercise-Specific Warm-Up",
        "Workbook 1",
        "Workbook 2"
    ]
    var body: some View {
        List {
            Section("Workouts") {
                ForEach(workoutDay, id: \.self) { day in
                    NavigationLink {
                        // Add Destination Here
                    } label: {
                        Text(day)
                    }
                }
            }
            Section("General Info") {
                ForEach(generalInfo, id: \.self) { item in
                    NavigationLink {
                        // Add Destination Here
                    } label: {
                        Text(item)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
