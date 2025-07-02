//
//  MovementInfoView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 7/1/25.
//

import SwiftUI

struct MovementInfoView: View {
    @EnvironmentObject var viewModel: ActiveExerciseViewModel
    var exercise: Exercise
    
    var body: some View {
        Group {
            // Target information
            VStack(alignment: .leading, spacing: 12) {
                targetInfoRow(title: "Target Sets", value: "\(exercise.warmUpSets) warm-up + \(exercise.workingSets) working")
                targetInfoRow(title: "Target Reps", value: "\(exercise.reps.lowerBound)-\(exercise.reps.upperBound)")
                targetInfoRow(title: "Rest Period", value: "\(exercise.rest.lowerBound)-\(exercise.rest.upperBound) min")
                targetInfoRow(title: "Intensity Technique", value: exercise.lastSetIntensityTechnique)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Example video
            VStack(alignment: .leading, spacing: 8) {
                Text("Example")
                    .font(.headline)
                    .padding(.horizontal)
                
                if let webView = viewModel.webView {
                    WebViewRepresentable(webView: webView)
                        .aspectRatio(1.8, contentMode: .fit)
                        .cornerRadius(12)
                        .frame(height: 200)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private func targetInfoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
