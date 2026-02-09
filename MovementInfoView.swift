//
//  MovementInfoView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 7/1/25.
//

import SwiftUI
import WebKit

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

            // Video section
            videoSection
        }
    }

    // MARK: - Video Section

    @ViewBuilder
    private var videoSection: some View {
        if let videoUrl = nativeVideoUrl {
            // Native video player from backend URL
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
        } else if !exercise.example.isEmpty {
            // Fallback to YouTube iframe from template data
            VStack(alignment: .leading, spacing: 8) {
                Text("Example")
                    .font(.headline)
                    .padding(.horizontal)

                YouTubeEmbedView(html: exercise.example)
                    .aspectRatio(1.8, contentMode: .fit)
                    .cornerRadius(12)
                    .frame(height: 200)
                    .padding(.horizontal)
            }
        }
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

// MARK: - YouTube Embed View

struct YouTubeEmbedView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        let wrapped = """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
        body { margin: 0; padding: 0; background: transparent; display: flex; justify-content: center; align-items: center; height: 100vh; }
        iframe { width: 100%; height: 100%; border: none; border-radius: 12px; }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
        webView.loadHTMLString(wrapped, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
