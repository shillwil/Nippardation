//
//  ReusableComponents.swift
//  Nippardation
//
//  Legacy shared components, restyled to Void. Signatures are unchanged so existing
//  call sites keep working; colours passed by callers are mapped onto the one-ink system.
//

import SwiftUI

// MARK: - Pill Badge

/// Small status label. Void is squared: radius 6, panel-2 (tinted) or plasma (filled).
struct PillBadge: View {
    let text: String
    var color: Color = VoidColor.plasma
    var style: PillStyle = .filled

    enum PillStyle {
        case filled
        case tinted
    }

    var body: some View {
        Text(text)
            .font(VoidFont.eyebrowSm)
            .tracking(VoidFont.Tracking.eyebrowSm)
            .textCase(.uppercase)
            .lineLimit(1)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: VoidRadius.mark, style: .continuous))
    }

    private var isWarning: Bool {
        color == .red || color == .orange || color == VoidColor.warning
    }

    private var foregroundColor: Color {
        switch style {
        case .filled:
            return VoidColor.onPlasma
        case .tinted:
            return isWarning ? VoidColor.warning : VoidColor.text2
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:
            return VoidColor.plasma
        case .tinted:
            return VoidColor.panel2
        }
    }
}

// MARK: - Stat Card

/// Metric card: glyph top-left, Michroma number, eyebrow label, optional trend.
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    var trend: StatTrend?
    var iconColor: Color = VoidColor.text

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
            VoidColor.text2
        }

        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "arrow.right"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .fontWeight(.medium)
                .frame(width: 24, height: 24)
                .foregroundStyle(VoidColor.text)

            Spacer(minLength: AppSpacing.sm)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(value)
                    .voidNumber()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let trend {
                    Text("\(label) · \(trend.text)")
                        .voidEyebrowSm()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text(label)
                        .voidEyebrowSm()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .frame(height: VoidSize.statTile, alignment: .topLeading)
        .voidPanel(radius: VoidRadius.panel, line: VoidColor.hairline)
    }
}

// MARK: - Section Header

/// Section eyebrow with an optional trailing action.
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
                .voidEyebrowSm()

            Spacer()

            if let action {
                Button(action: action.handler) {
                    Text(action.label)
                        .font(VoidFont.buttonSm)
                        .foregroundStyle(VoidColor.plasma)
                }
                .buttonStyle(VoidPlainButtonStyle())
            }
        }
    }
}

// MARK: - Icon Circle (now a squared Void tile)

/// Squared glyph tile: radius 12, panel-2 fill, glyph in text.
struct IconCircle: View {
    let icon: String
    var color: Color = VoidColor.text
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(VoidColor.text)
            .frame(width: size, height: size)
            .background(VoidColor.panel2)
            .clipShape(RoundedRectangle(cornerRadius: size >= 40 ? VoidRadius.tile : VoidRadius.avatar, style: .continuous))
    }
}

// MARK: - Previews

#Preview("Pill Badges") {
    HStack(spacing: AppSpacing.xs) {
        PillBadge(text: "Active")
        PillBadge(text: "Compound", style: .tinted)
        PillBadge(text: "Warmup", color: .orange, style: .tinted)
        PillBadge(text: "8 Weeks", style: .tinted)
    }
    .padding()
    .background(VoidColor.hull)
}

#Preview("Stat Cards") {
    HStack(spacing: AppSpacing.sm) {
        StatCard(icon: "flame.fill", value: "04", label: "This Week", trend: .up("+1"))
        StatCard(icon: "dumbbell", value: "12.4", label: "Volume", trend: .up("+8%"))
    }
    .padding()
    .background(VoidColor.hull)
}

#Preview("Section Header") {
    VStack(spacing: AppSpacing.lg) {
        SectionHeader(title: "Recent Workouts")
        SectionHeader(title: "My Plans", action: .init(label: "See All", handler: {}))
    }
    .padding()
    .background(VoidColor.hull)
}

#Preview("Icon Tiles") {
    HStack(spacing: AppSpacing.sm) {
        IconCircle(icon: "dumbbell.fill")
        IconCircle(icon: "figure.strengthtraining.traditional")
        IconCircle(icon: "flame.fill", size: 32)
    }
    .padding()
    .background(VoidColor.hull)
}
