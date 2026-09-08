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
                    Image(systemName: VoidIcon.play.systemName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(VoidColor.plasma)
                        .frame(width: 50, height: 50)
                        .background(VoidColor.panel)
                        .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous)
                                .strokeBorder(VoidColor.hairline2, lineWidth: 1)
                        )
                }
                .buttonStyle(VoidScaleButtonStyle())
                .accessibilityLabel("Play video")
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .background(VoidColor.hull)
        .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous)
                .strokeBorder(VoidColor.hairline2, lineWidth: 1)
        )
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
                                .tint(VoidColor.text)
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
            .fill(VoidColor.panel2)
            .overlay(
                Image(systemName: VoidIcon.workoutDefault.systemName)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(VoidColor.text3)
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
                .padding(.horizontal, VoidSpace.insetCard)

                Spacer()
            }
            .navigationTitle("Exercise demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showFullPlayer = false
                    }
                }
            }
            .voidScreen()
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
    .background(VoidColor.hull)
}
