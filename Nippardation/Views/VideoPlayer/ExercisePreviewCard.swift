//
//  ExercisePreviewCard.swift
//  Nippardation
//
//  Auto-playing muted video preview card for exercise carousel
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Video / thumbnail area
            ZStack {
                Color.black

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
                        .tint(.white)
                }
            }
            .frame(width: cardWidth, height: cardWidth)
            .clipped()
            .cornerRadius(AppCornerRadius.medium, corners: [.topLeft, .topRight])

            // Info area
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(libraryItem?.name ?? templateExercise.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                HStack(spacing: AppSpacing.xxs) {
                    if let muscle = libraryItem?.primaryMuscles.first {
                        PillBadge(
                            text: muscle.rawValue.capitalized,
                            color: .appTheme,
                            style: .tinted
                        )
                    }

                    Spacer()

                    Text(templateExercise.setSummary)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(AppSpacing.xs)
            .frame(width: cardWidth, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.medium, corners: [.bottomLeft, .bottomRight])
        }
        .frame(width: cardWidth)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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

    private var placeholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - Corner Radius Helper

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

private struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
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
}
