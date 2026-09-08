//
//  ExerciseVideoCarousel.swift
//  Nippardation
//
//  Reusable horizontal scroll of auto-playing exercise video preview cards
//

import SwiftUI

/// Horizontal scroll of auto-playing exercise video preview cards for a template.
/// Shows each exercise as a small looping video with name and muscle group.
struct ExerciseVideoCarousel: View {

    let template: Template
    var title: String? = "Exercises"

    private var exercises: [TemplateExercise] {
        template.exercises
            .sorted { $0.orderIndex < $1.orderIndex }
            .filter { $0.exerciseLibraryItem != nil }
    }

    var body: some View {
        if !exercises.isEmpty {
            VStack(alignment: .leading, spacing: VoidSpace.s3) {
                if let title {
                    VoidSectionRow(title: title)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(exercises) { exercise in
                            ExercisePreviewCard(templateExercise: exercise)
                        }
                    }
                    .padding(.horizontal, VoidSpace.insetCard)
                }
            }
            .task {
                // Prefetch videos for this template so they're cached ahead of scroll
                await DependencyContainer.shared.videoCacheService.prefetchVideos(for: template.serverId)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ExerciseVideoCarousel(
        template: MockTemplateRepository.sampleTemplates.first ?? .empty(),
        title: "Up Next"
    )
    .withDependencies(.preview)
    .background(VoidColor.hull)
}
