//
//  ExercisePreviewCard.swift
//  Nippardation
//
//  Auto-playing muted video preview card for exercise carousel
//  Void chrome: radius 12, panel fill, hairline, SF 13 name, eyebrow-sm caption, no shadow.
//

import SwiftUI
import AVFoundation

/// A compact card that auto-plays an exercise video muted and looping.
/// Shows exercise name and muscle group below the video area.
struct ExercisePreviewCard: View {

    let templateExercise: TemplateExercise
    var cardWidth: CGFloat = 130

    @StateObject private var viewModel = VideoPlayerViewModel()

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
                if viewModel.error != nil && hasVideo && !viewModel.isLoading {
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(caption)")
        .task {
            guard let item = libraryItem else { return }
            await viewModel.loadVideo(
                exerciseServerId: item.serverId,
                videoUrl: item.videoUrl
            )
        }
        .onDisappear {
            viewModel.pause()
        }
    }

    // MARK: - Subviews

    private var errorOverlay: some View {
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
        .onTapGesture {
            guard let item = libraryItem else { return }
            Task {
                await viewModel.loadVideo(
                    exerciseServerId: item.serverId,
                    videoUrl: item.videoUrl
                )
            }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Video failed to load. Tap to retry")
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
