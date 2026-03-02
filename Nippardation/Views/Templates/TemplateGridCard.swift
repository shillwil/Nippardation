//
//  TemplateGridCard.swift
//  Nippardation
//
//  Grid card for displaying a template in the 2-column grid
//

import SwiftUI

struct TemplateGridCard: View {
    let template: Template

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Icon circle with color derived from name
            HStack {
                IconCircle(
                    icon: iconForTemplate,
                    color: colorForTemplate,
                    size: 36
                )

                Spacer()

                if template.isAiGenerated {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .font(.caption2)
                }
            }

            // Template name
            Text(template.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .foregroundColor(.primary)

            // Exercise count
            Text("\(template.exerciseCount) exercises")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer(minLength: 0)

            // Last modified
            Text(formattedDate)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Helpers

    private var iconForTemplate: String {
        let name = template.name.lowercased()
        if name.contains("push") { return "arrow.up.circle.fill" }
        if name.contains("pull") { return "arrow.down.circle.fill" }
        if name.contains("leg") { return "figure.walk" }
        if name.contains("upper") { return "figure.arms.open" }
        if name.contains("lower") { return "figure.step.training" }
        return "dumbbell.fill"
    }

    private var colorForTemplate: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal]
        let hash = template.name.utf8.reduce(0) { $0 &+ Int($1) }
        return colors[abs(hash) % colors.count]
    }

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private var formattedDate: String {
        Self.relativeDateFormatter.localizedString(for: template.updatedAt, relativeTo: Date())
    }
}

// MARK: - Previews

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
        TemplateGridCard(template: MockTemplateRepository.sampleTemplates[0])
        TemplateGridCard(template: MockTemplateRepository.sampleTemplates[1])
    }
    .padding()
    .withDependencies(.preview)
}
