//
//  NativeVideoPlayer.swift
//  Nippardation
//
//  Exercise demo player. The video and its controls are AVKit's system `VideoPlayer`
//  (an AVPlayerViewController underneath), so the transport controls, their Liquid Glass
//  look and their VoiceOver support come from iOS. SwiftUI's VideoPlayer shows no
//  full-screen or Picture in Picture button. Void adds only the 12pt frame, the hull
//  backdrop behind the loading and error states, and the plasma tint.
//
//  Loading through the video cache, download progress, aspect-ratio detection, muting,
//  looping, and when a demo may start by itself (Auto-Play Video Previews, a pause made with
//  the controls) live in `VideoPlayerViewModel`.
//
//  Audio: the demo files carry a silent audio track, so AVPlayer activates the app's audio
//  session even while muted. The session category is Ambient (`AppAudioSession`), or every
//  demo would stop the music people are working out to.
//

import SwiftUI
import AVKit

/// Muted, looping exercise demo, loaded through the video cache. It plays by itself while
/// Auto-Play Video Previews is on.
struct NativeVideoPlayer: View {

    // MARK: - Properties

    let exerciseServerId: String
    let videoUrl: URL?

    @StateObject private var viewModel = VideoPlayerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    private var frameShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous)
    }

    /// A change to either value (a swapped movement, a refreshed URL) loads the new video.
    private struct Source: Equatable {
        let exerciseServerId: String
        let videoUrl: URL?
    }

    // MARK: - Initialization

    init(exerciseServerId: String, videoUrl: URL?) {
        self.exerciseServerId = exerciseServerId
        self.videoUrl = videoUrl
    }

    // MARK: - Body

    var body: some View {
        // A plain container, so switching between the player and the error state
        // doesn't restart the task or fire onDisappear.
        ZStack {
            if let message = viewModel.error {
                errorView(message: message)
            } else {
                player
            }
        }
        // Runs on appear and again whenever the source changes, so a swap loads exactly once.
        .task(id: Source(exerciseServerId: exerciseServerId, videoUrl: videoUrl)) {
            await viewModel.loadVideo(exerciseServerId: exerciseServerId, videoUrl: videoUrl)
        }
        // Scrolling the sheet (or lowering it to a small detent) hides the demo without
        // removing it. Pause while it's off screen; resume when it comes back, unless it was
        // paused with the controls.
        .onScrollVisibilityChange(threshold: 0.2) { isVisible in
            if isVisible {
                viewModel.play()
            } else {
                viewModel.pause()
            }
        }
        .onDisappear {
            viewModel.pause()
        }
        // iOS pauses the player when the app leaves the foreground (the phone locked between
        // sets, say), and nothing above fires on return. Leaving doesn't count as going off
        // screen, so the view model still knows whether to resume.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.resumeIfWanted()
            }
        }
    }

    // MARK: - Player

    private var player: some View {
        VideoPlayer(player: viewModel.player)
            // Keep VoiceOver off the system controls while the loading state covers them.
            .accessibilityHidden(viewModel.isLoading)
            // Required: in a scroll view the player has no height of its own. Sizing it to
            // the video's own ratio also means the video is never letterboxed.
            .aspectRatio(viewModel.detectedAspectRatio, contentMode: .fit)
            .overlay {
                if viewModel.isLoading {
                    loadingView
                }
            }
            .clipShape(frameShape)
            .animation(.easeInOut(duration: 0.25), value: viewModel.detectedAspectRatio)
    }

    // MARK: - States

    /// Opaque hull while the file loads, so the player's black backdrop never shows.
    private var loadingView: some View {
        ZStack {
            VoidColor.hull

            if let fraction = downloadFraction {
                ProgressView(value: fraction) {
                    Text("Downloading video")
                        .font(VoidFont.caption)
                        .foregroundStyle(VoidColor.text2)
                } currentValueLabel: {
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                }
                .tint(VoidColor.plasma)
                .padding(.horizontal, VoidSpace.s6)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .accessibilityLabel("Loading video")
            }
        }
    }

    /// Download progress while a download is under way; nil shows the spinner instead.
    private var downloadFraction: Double? {
        let progress = viewModel.downloadProgress
        return (progress > 0 && progress < 1) ? progress : nil
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Video unavailable", systemImage: "video.slash")
        } description: {
            Text(message)
        } actions: {
            Button {
                Task {
                    await viewModel.loadVideo(exerciseServerId: exerciseServerId, videoUrl: videoUrl)
                }
            } label: {
                // Side by side: iOS 26 stacks an action's icon over its title by default.
                Label("Retry", systemImage: "arrow.clockwise")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.bordered)
            // Neutral: plasma text on the light hull falls short of contrast.
            .tint(VoidColor.text)
            .fixedSize()
        }
        // Its own height, not whatever the row offers: a stretched state stretches the button.
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .background(VoidColor.hull)
        .clipShape(frameShape)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        NativeVideoPlayer(
            exerciseServerId: "test-exercise",
            videoUrl: URL(string: "https://pub-383015826a924878acc220637944c283.r2.dev/Dips.mp4")
        )
        .frame(maxHeight: 400)
        .padding(.horizontal, VoidSpace.insetCard)
    }
}
