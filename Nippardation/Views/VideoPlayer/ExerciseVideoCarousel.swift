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
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let title {
                    SectionHeader(title: title)
                        .padding(.horizontal, AppSpacing.md)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: AppSpacing.sm) {
                        ForEach(exercises) { exercise in
                            ExercisePreviewCard(templateExercise: exercise)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
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
}
