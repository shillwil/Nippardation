//
//  WorkoutStatsTabView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/18/25.
//

import SwiftUI

struct WorkoutStatsTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Chart Type", selection: $selectedTab) {
                Text("Volume").tag(0)
                Text("Top Exercises").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Tab content
            TabView(selection: $selectedTab) {
                WorkoutStatsView()
                    .tag(0)
                
                TopExercisesView()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 300)
        }
    }
}

#Preview {
    WorkoutStatsTabView()
}
