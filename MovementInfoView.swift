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

    /// Optional native video URL for R2-hosted MP4 videos
    /// When provided, displays native AVPlayer instead of WebView
    var nativeVideoUrl: URL?

    /// Optional exercise server ID for video caching
    var exerciseServerId: String?

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

            // Video section - only show if native video URL is available
            videoSection
        }
    }

    // MARK: - Video Section

    @ViewBuilder
    private var videoSection: some View {
        if let videoUrl = nativeVideoUrl {
            VStack(alignment: .leading, spacing: 8) {
                Text("Example")
                    .font(.headline)
                    .padding(.horizontal)

                NativeVideoPlayer(
                    exerciseServerId: exerciseServerId ?? exercise.type.name,
                    videoUrl: videoUrl,
                    aspectRatio: 16/9,
                    showControls: true
                )
                .frame(height: 220)
                .padding(.horizontal)
            }
        }
        // When no native video URL is available, gracefully degrade by showing nothing
        // This replaces the old WebView-based YouTube player
    }

    // MARK: - Helper Views

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
