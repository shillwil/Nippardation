//
//  NativeVideoPlayer.swift
//  Nippardation
//
//  Native video player view using AVPlayer
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
                .background(Color.black)
                .cornerRadius(12)

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
            Color.black.opacity(0.3)

            VStack(spacing: 12) {
                if viewModel.downloadProgress > 0 && viewModel.downloadProgress < 1 {
                    // Download progress
                    ProgressView(value: viewModel.downloadProgress)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)

                    Text("Downloading... \(Int(viewModel.downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.white)
                } else {
                    // Indeterminate loading
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)

                    Text("Loading video...")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
        .cornerRadius(12)
    }

    private func errorOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.5)

            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title)
                    .foregroundColor(.yellow)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Button("Retry") {
                    Task {
                        await viewModel.loadVideo(exerciseServerId: exerciseServerId, videoUrl: videoUrl)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
            .padding()
        }
        .cornerRadius(12)
    }

    private var controlsOverlay: some View {
        VStack {
            Spacer()

            HStack(spacing: 20) {
                // Play/Pause button
                Button {
                    viewModel.togglePlayPause()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }

                // Progress bar
                if viewModel.duration > 0 {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 4)

                            // Progress
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(
                                    width: max(0, min(geometry.size.width, geometry.size.width * CGFloat(viewModel.currentTime / viewModel.duration))),
                                    height: 4
                                )
                        }
                        .frame(height: 4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 20)
                }

                // Mute button
                Button {
                    viewModel.toggleMute()
                } label: {
                    Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .cornerRadius(12)
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
}
