//
//  ReusableComponents.swift
//  Nippardation
//
//  Reusable UI components for the design system
//

import SwiftUI

// MARK: - Pill Badge

/// Colored pill for status text (Active, Warmup, Compound, etc.)
struct PillBadge: View {
    let text: String
    var color: Color = .blue
    var style: PillStyle = .filled

    enum PillStyle {
        case filled
        case tinted
    }

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .cornerRadius(AppCornerRadius.small)
    }

    private var foregroundColor: Color {
        switch style {
        case .filled:
            return .white
        case .tinted:
            return color
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:
            return color
        case .tinted:
            return color.opacity(0.15)
        }
    }
}

// MARK: - Stat Card

/// Metric display card with icon, value, label, and optional trend
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    var trend: StatTrend?
    var iconColor: Color = .blue

    enum StatTrend {
        case up(String)
        case down(String)
        case neutral(String)

        var text: String {
            switch self {
            case .up(let val), .down(let val), .neutral(let val):
                return val
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .secondary
            }
        }

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            if let trend {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: trend.icon)
                        .font(.caption2)
                    Text(trend.text)
                        .font(.caption2)
                }
                .foregroundColor(trend.color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .cardStyle()
    }
}

// MARK: - Section Header

/// Consistent section header with optional trailing action
struct SectionHeader: View {
    let title: String
    var action: SectionAction?

    struct SectionAction {
        let label: String
        let handler: () -> Void
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)

            Spacer()

            if let action {
                Button(action: action.handler) {
                    Text(action.label)
                        .font(.subheadline)
                        .foregroundColor(.appTheme)
                }
            }
        }
    }
}

// MARK: - Icon Circle

/// Colored circle with an SF Symbol icon inside
struct IconCircle: View {
    let icon: String
    var color: Color = .blue
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.4))
            .foregroundColor(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.15))
            .clipShape(Circle())
    }
}

// MARK: - Previews

#Preview("Pill Badges") {
    HStack(spacing: AppSpacing.xs) {
        PillBadge(text: "Active", color: .green)
        PillBadge(text: "Compound", color: .blue, style: .tinted)
        PillBadge(text: "Warmup", color: .orange, style: .tinted)
        PillBadge(text: "8 Weeks", color: .purple, style: .tinted)
    }
    .padding()
}

#Preview("Stat Cards") {
    HStack(spacing: AppSpacing.sm) {
        StatCard(
            icon: "flame.fill",
            value: "4",
            label: "This Week",
            trend: .up("+1"),
            iconColor: .orange
        )
        StatCard(
            icon: "scalemass.fill",
            value: "12.4K",
            label: "Volume (lbs)",
            trend: .up("+8%"),
            iconColor: .blue
        )
    }
    .padding()
}

#Preview("Section Header") {
    VStack(spacing: AppSpacing.lg) {
        SectionHeader(title: "Recent Workouts")
        SectionHeader(
            title: "My Programs",
            action: .init(label: "See All", handler: {})
        )
    }
    .padding()
}

#Preview("Icon Circles") {
    HStack(spacing: AppSpacing.sm) {
        IconCircle(icon: "dumbbell.fill", color: .blue)
        IconCircle(icon: "figure.strengthtraining.traditional", color: .green)
        IconCircle(icon: "heart.fill", color: .red, size: 32)
    }
    .padding()
}
