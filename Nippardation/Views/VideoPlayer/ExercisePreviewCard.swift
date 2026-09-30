//
//  ExercisePreviewCard.swift
//  Nippardation
//
//  Auto-playing muted video preview card for exercise carousel
//  Void chrome: radius 12, panel fill, hairline, SF 13 name, eyebrow-sm caption, no shadow.
//  The tile is a silent animated thumbnail, not a player: it draws the video on AVFoundation's
//  own AVPlayerLayer (aspect-fill, no controls). The exercise sheet uses AVKit's VideoPlayer.
//  With no controls to stop it, a tile animates only while Auto-Play Video Previews is on;
//  off, it shows the video's first frame.
//

import SwiftUI
import AVFoundation
import UIKit

/// A compact card that auto-plays an exercise video muted and looping (while Auto-Play
/// Video Previews is on). Shows exercise name and muscle group below the video area.
struct ExercisePreviewCard: View {

    let templateExercise: TemplateExercise
    var cardWidth: CGFloat = 130

    @StateObject private var viewModel = VideoPlayerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    private var libraryItem: ExerciseLibraryItem? {
        templateExercise.exerciseLibraryItem
    }

    private var hasVideo: Bool {
        libraryItem?.videoUrl != nil
    }

    private var name: String {
        libraryItem?.name ?? templateExercise.displayName
    }

    /// `CHEST · 3 × 8-12`
    private var caption: String {
        VoidFormat.readout([
            libraryItem?.primaryMuscles.first?.rawValue,
            "\(templateExercise.workingSets) × \(templateExercise.targetReps ?? "?")"
        ])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Video / thumbnail area
            ZStack {
                VoidColor.hull

                if hasVideo {
                    VideoPlayerLayer(
                        player: viewModel.player,
                        videoGravity: .resizeAspectFill
                    )
                } else {
                    placeholder
                }

                // Loading indicator
                if viewModel.isLoading && hasVideo {
                    ProgressView()
                        .tint(VoidColor.text)
                }

                // Error state
                if hasFailed {
                    errorOverlay
                }
            }
            .frame(width: cardWidth, height: cardWidth)
            .clipped()

            // Info area
            VStack(alignment: .leading, spacing: VoidSpace.s1) {
                Text(name)
                    .font(VoidFont.caption)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(1)

                Text(caption)
                    .voidEyebrowSm()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(10)
            .frame(width: cardWidth, alignment: .leading)
        }
        .frame(width: cardWidth)
        .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(caption)")
        .accessibilityActions {
            if hasFailed {
                Button("Retry video", action: retry)
            }
        }
        .task {
            guard let item = libraryItem else { return }
            await viewModel.loadVideo(
                exerciseServerId: item.serverId,
                videoUrl: item.videoUrl
            )
        }
        // LazyHStack keeps nearby tiles alive; only tiles on screen decode video.
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
        // iOS pauses the player when the app leaves the foreground; without this every tile
        // on screen stays frozen on one frame after the app returns.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.resumeIfWanted()
            }
        }
    }

    private var hasFailed: Bool {
        viewModel.error != nil && hasVideo && !viewModel.isLoading
    }

    private func retry() {
        guard let item = libraryItem else { return }
        Task {
            await viewModel.loadVideo(
                exerciseServerId: item.serverId,
                videoUrl: item.videoUrl
            )
        }
    }

    // MARK: - Subviews

    private var errorOverlay: some View {
        Button(action: retry) {
            ZStack {
                VoidColor.hull.opacity(0.7)

                VStack(spacing: VoidSpace.s1) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(VoidColor.text)

                    Text("Tap to retry")
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var placeholder: some View {
        Rectangle()
            .fill(VoidColor.panel2)
            .overlay(
                Image(systemName: VoidIcon.workoutDefault.systemName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(VoidColor.text3)
            )
    }
}

// MARK: - Player layer

/// Hosts the card's AVPlayer on a bare AVPlayerLayer: aspect-fill and no controls, which
/// AVKit's VideoPlayer can't do.
private struct VideoPlayerLayer: UIViewRepresentable {
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

/// UIView whose backing layer is an AVPlayerLayer.
private final class PlayerUIView: UIView {

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
    HStack(spacing: 10) {
        ExercisePreviewCard(
            templateExercise: TemplateExercise(
                id: UUID(),
                serverId: "",
                exerciseServerId: "test",
                exerciseLibraryItem: ExerciseLibraryItem(
                    id: UUID(),
                    serverId: "test",
                    name: "Bench Press",
                    primaryMuscles: [.chest],
                    secondaryMuscles: [],
                    equipment: .barbell,
                    difficulty: .intermediate,
                    movementPattern: .push,
                    exerciseType: .compound,
                    instructions: nil,
                    videoUrl: nil,
                    thumbnailUrl: nil,
                    popularityScore: 0,
                    lastFetchedAt: nil
                ),
                orderIndex: 0,
                warmupSets: 2,
                workingSets: 3,
                targetReps: "8-12",
                restSeconds: 90,
                notes: nil
            )
        )

        ExercisePreviewCard(
            templateExercise: TemplateExercise(
                id: UUID(),
                serverId: "",
                exerciseServerId: "test2",
                exerciseLibraryItem: nil,
                orderIndex: 1,
                warmupSets: nil,
                workingSets: 4,
                targetReps: "6-8",
                restSeconds: 120,
                notes: nil
            )
        )
    }
    .padding()
    .background(VoidColor.hull)
}
