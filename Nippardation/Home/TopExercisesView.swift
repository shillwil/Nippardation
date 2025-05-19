//
//  TopExercisesView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/18/25.
//

import SwiftUI
import Charts

struct TopExercisesView: View {
    @ObservedObject var workoutManager = WorkoutManager.shared
    @State private var timeRange: TimeRange = .month
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case month = "Month"
        case allTime = "All Time"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Top Exercises")
                    .font(.headline)
                
                Spacer()
                
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            
            let topExercises = workoutManager.getTopExercises(limit: 5)
            
            if topExercises.isEmpty {
                Text("No exercise data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart {
                    ForEach(topExercises, id: \.name) { exercise in
                        BarMark(
                            x: .value("Volume", exercise.volume),
                            y: .value("Exercise", exercise.name)
                        )
                        .foregroundStyle(Color.appTheme.gradient)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartXScale(domain: .automatic(includesZero: true))
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    TopExercisesView()
}
