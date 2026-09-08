//
//  AppDesignSystem.swift
//  Nippardation
//
//  Legacy design tokens and card modifiers, re-pointed at the Void system.
//  Existing call sites keep compiling; every card now renders as a flat Void panel
//  (panel fill, 1pt hairline, squared radius, no shadow, no gradient).
//  New code should use VoidTheme / VoidComponents directly.
//

import SwiftUI

// MARK: - Spacing Scale

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius Tokens (Void: squared, never pills)

enum AppCornerRadius {
    /// Small controls (···, segmented).
    static let small: CGFloat = VoidRadius.control
    /// Tiles, pills, stepper wells.
    static let medium: CGFloat = VoidRadius.tile
    /// Cards and stat tiles.
    static let large: CGFloat = VoidRadius.panel
    /// Hero panels, tab bar, sheets.
    static let xl: CGFloat = VoidRadius.tabBar
}

// MARK: - Shadow Presets

/// Void has no card shadows. The only shadows in the system are the tab bar and the Start glow.
struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let none = AppShadow(color: .clear, radius: 0, x: 0, y: 0)
    static let card = AppShadow.none
    static let elevated = AppShadow.none
    static let floating = AppShadow.none
}

// MARK: - Card View Modifier

struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppCornerRadius.large
    var shadow: AppShadow = .card
    var hasBorder: Bool = false
    var borderColor: Color = VoidColor.hairline2
    var backgroundColor: Color = VoidColor.panel

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(hasBorder ? borderColor : VoidColor.hairline, lineWidth: 1)
            )
    }
}

// MARK: - Dashed Card View Modifier

struct DashedCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppCornerRadius.large
    var dashColor: Color = VoidColor.hairline2
    var lineWidth: CGFloat = 1
    var dash: [CGFloat] = [6, 5]

    func body(content: Content) -> some View {
        content
            .background(VoidColor.panel.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: lineWidth, dash: dash))
                    .foregroundStyle(dashColor)
            )
    }
}

// MARK: - Gradient Card View Modifier (now flat — Void has no gradients)

struct GradientCardModifier: ViewModifier {
    var colors: [Color]
    var cornerRadius: CGFloat = AppCornerRadius.xl
    var hasBorder: Bool = true
    var borderColor: Color = VoidColor.hairline2

    func body(content: Content) -> some View {
        content
            .background(VoidColor.panel)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(hasBorder ? borderColor : VoidColor.hairline, lineWidth: 1)
            )
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(
        cornerRadius: CGFloat = AppCornerRadius.large,
        shadow: AppShadow = .card,
        hasBorder: Bool = false,
        borderColor: Color = VoidColor.hairline2,
        backgroundColor: Color = VoidColor.panel
    ) -> some View {
        modifier(CardModifier(
            cornerRadius: cornerRadius,
            shadow: shadow,
            hasBorder: hasBorder,
            borderColor: borderColor,
            backgroundColor: backgroundColor
        ))
    }

    func dashedCardStyle(
        cornerRadius: CGFloat = AppCornerRadius.large,
        dashColor: Color = VoidColor.hairline2
    ) -> some View {
        modifier(DashedCardModifier(
            cornerRadius: cornerRadius,
            dashColor: dashColor
        ))
    }

    func gradientCardStyle(
        colors: [Color] = [VoidColor.panel, VoidColor.panel],
        cornerRadius: CGFloat = AppCornerRadius.xl,
        hasBorder: Bool = true,
        borderColor: Color = VoidColor.hairline2
    ) -> some View {
        modifier(GradientCardModifier(
            colors: colors,
            cornerRadius: cornerRadius,
            hasBorder: hasBorder,
            borderColor: borderColor
        ))
    }
}

// MARK: - Previews

#Preview("Card Styles") {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            Text("Standard Card")
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .cardStyle()

            Text("Card with Border")
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .cardStyle(hasBorder: true)

            Text("Dashed Card")
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .dashedCardStyle()

            Text("Hero Panel")
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .gradientCardStyle()
        }
        .padding(AppSpacing.md)
        .foregroundStyle(VoidColor.text)
    }
    .background(VoidColor.hull)
}
