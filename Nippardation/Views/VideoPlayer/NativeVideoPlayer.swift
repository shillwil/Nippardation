//
//  NativeVideoPlayer.swift
//  Nippardation
//
//  Native video player view using AVPlayer
//  Void chrome: hull backdrop, radius 12, plasma controls, flat overlays (no gradients).
//

import SwiftUI
import AVFoundation
import AVKit

/// Native video player view using AVPlayer
struct NativeVideoPlayer: View {

    // MARK: - Properties

    @StateObject private var viewModel: VideoPlayerViewModel

    let exerciseServerId: String
    let videoUrl: URL?
    let overrideAspectRatio: CGFloat?
    let showControls: Bool

    private var effectiveAspectRatio: CGFloat {
        overrideAspectRatio ?? viewModel.detectedAspectRatio
    }

    private var frameShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous)
    }

    // MARK: - Initialization

    init(
        exerciseServerId: String,
        videoUrl: URL?,
        overrideAspectRatio: CGFloat? = nil,
        showControls: Bool = true
    ) {
        self.exerciseServerId = exerciseServerId
        self.videoUrl = videoUrl
        self.overrideAspectRatio = overrideAspectRatio
        self.showControls = showControls
        self._viewModel = StateObject(wrappedValue: VideoPlayerViewModel())
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Video layer
            VideoPlayerLayer(player: viewModel.player)
                .aspectRatio(effectiveAspectRatio, contentMode: .fit)
                .animation(.easeInOut(duration: 0.25), value: effectiveAspectRatio)
                .background(VoidColor.hull)
                .clipShape(frameShape)

            // Loading overlay
            if viewModel.isLoading {
                loadingOverlay
            }

            // Error overlay
            if let error = viewModel.error {
                errorOverlay(message: error)
            }

            // Controls overlay
            if showControls && !viewModel.isLoading && viewModel.error == nil {
                controlsOverlay
            }
        }
        .task {
            await viewModel.loadVideo(exerciseServerId: exerciseServerId, videoUrl: videoUrl)
        }
        .onChange(of: exerciseServerId) { oldId, newId in
            // Only reload if the ID actually changed
            guard oldId != newId else { return }
            Task {
                await viewModel.loadVideo(exerciseServerId: newId, videoUrl: videoUrl)
            }
        }
        .onChange(of: videoUrl) { oldUrl, newUrl in
            // Reload if video URL changes (even with same exercise ID)
            guard oldUrl != newUrl else { return }
            Task {
                await viewModel.loadVideo(exerciseServerId: exerciseServerId, videoUrl: newUrl)
            }
        }
        .onDisappear {
            viewModel.pause()
        }
    }

    // MARK: - Subviews

    private var loadingOverlay: some View {
        ZStack {
            VoidColor.hull.opacity(0.7)

            VStack(spacing: VoidSpace.s3) {
                if viewModel.downloadProgress > 0 && viewModel.downloadProgress < 1 {
                    // Download progress
                    ProgressView(value: viewModel.downloadProgress)
                        .progressViewStyle(CircularProgressViewStyle(tint: VoidColor.text))
                        .scaleEffect(1.2)

                    Text("Downloading \(VoidFormat.pad2(Int(viewModel.downloadProgress * 100)))%")
                        .voidEyebrowSm()
                } else {
                    // Indeterminate loading
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: VoidColor.text))
                        .scaleEffect(1.2)

                    Text("Loading video")
                        .voidEyebrowSm()
                }
            }
        }
        .clipShape(frameShape)
    }

    private func errorOverlay(message: String) -> some View {
        ZStack {
            VoidColor.hull.opacity(0.7)

            VStack(spacing: VoidSpace.s3) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(VoidColor.warning)

                Text(message)
                    .font(VoidFont.caption)
                    .foregroundStyle(VoidColor.text)
                    .multilineTextAlignment(.center)

                VoidPillButton(title: "Retry") {
                    Task {
                        await viewModel.loadVideo(exerciseServerId: exerciseServerId, videoUrl: videoUrl)
                    }
                }
                .frame(width: 120)
            }
            .padding()
        }
        .clipShape(frameShape)
    }

    private var controlsOverlay: some View {
        VStack {
            Spacer()

            HStack(spacing: VoidSpace.s4) {
                // Play/Pause button
                controlButton(
                    systemName: viewModel.isPlaying ? VoidIcon.pause.systemName : VoidIcon.play.systemName,
                    size: VoidSize.hitMin,
                    label: viewModel.isPlaying ? "Pause" : "Play"
                ) {
                    viewModel.togglePlayPause()
                }

                // Progress bar
                if viewModel.duration > 0 {
                    VoidProgressBar(progress: viewModel.currentTime / viewModel.duration)
                        .frame(maxWidth: .infinity)
                }

                // Mute button
                controlButton(
                    systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                    size: VoidSize.hitMin,
                    glyphSize: 14,
                    label: viewModel.isMuted ? "Unmute" : "Mute"
                ) {
                    viewModel.toggleMute()
                }
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.vertical, VoidSpace.s3)
            .background(VoidColor.hull.opacity(0.7))
        }
        .clipShape(frameShape)
    }

    /// Squared control: panel fill, hairline, plasma glyph. `size` is the tappable square
    /// (`VoidPanelButtonStyle` clips the hit area to it, so keep it at `VoidSize.hitMin`);
    /// `glyphSize` lets a secondary control keep a smaller glyph.
    private func controlButton(systemName: String, size: CGFloat, glyphSize: CGFloat = 17, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: glyphSize, weight: .semibold))
                .foregroundStyle(VoidColor.plasma)
                .frame(width: size, height: size)
        }
        .buttonStyle(VoidPanelButtonStyle(radius: VoidRadius.control))
        .accessibilityLabel(label)
    }
}

// MARK: - Video Player Layer

/// UIViewRepresentable wrapper for AVPlayerLayer
struct VideoPlayerLayer: UIViewRepresentable {
    let player: AVPlayer
    var videoGravity: AVLayerVideoGravity = .resizeAspect

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.player = player
        view.playerLayer.videoGravity = videoGravity
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.player = player
        uiView.playerLayer.videoGravity = videoGravity
    }
}

/// UIView that hosts an AVPlayerLayer
class PlayerUIView: UIView {

    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
}

// MARK: - Preview

#Preview {
    NativeVideoPlayer(
        exerciseServerId: "test-exercise",
        videoUrl: URL(string: "https://pub-bd9be4594e0b4c538a1e72055ea5b6fc.r2.dev/exercises/bench-press.mp4")
    )
    .frame(height: 250)
    .padding()
    .background(VoidColor.hull)
}
