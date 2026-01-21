//
//  CompactVideoPlayer.swift
//  Nippardation
//
//  Compact video player for use in lists and smaller spaces
//

import SwiftUI

/// Compact video player for use in lists and smaller spaces
/// Shows thumbnail with play button, opens full player in sheet
struct CompactVideoPlayer: View {

    let exerciseServerId: String
    let videoUrl: URL?
    let thumbnailUrl: URL?

    @State private var showFullPlayer = false

    var body: some View {
        ZStack {
            // Thumbnail or placeholder
            thumbnailView

            // Play button overlay
            if videoUrl != nil {
                Button {
                    showFullPlayer = true
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .background(Color.black)
        .cornerRadius(8)
        .sheet(isPresented: $showFullPlayer) {
            fullPlayerSheet
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailUrl = thumbnailUrl {
            AsyncImage(url: thumbnailUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                case .failure:
                    placeholder
                case .empty:
                    placeholder
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            )
    }

    private var fullPlayerSheet: some View {
        NavigationStack {
            VStack {
                Spacer()

                NativeVideoPlayer(
                    exerciseServerId: exerciseServerId,
                    videoUrl: videoUrl,
                    showControls: true
                )
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Exercise Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showFullPlayer = false
                    }
                }
            }
            .background(Color.black)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CompactVideoPlayer(
            exerciseServerId: "test-exercise",
            videoUrl: URL(string: "https://pub-bd9be4594e0b4c538a1e72055ea5b6fc.r2.dev/exercises/bench-press.mp4"),
            thumbnailUrl: nil
        )
        .frame(width: 200)

        CompactVideoPlayer(
            exerciseServerId: "no-video",
            videoUrl: nil,
            thumbnailUrl: nil
        )
        .frame(width: 200)
    }
    .padding()
}
