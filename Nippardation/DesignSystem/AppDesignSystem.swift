//
//  AppDesignSystem.swift
//  Nippardation
//
//  Centralized design tokens and reusable view modifiers
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

// MARK: - Corner Radius Tokens

enum AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - Shadow Presets

struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let card = AppShadow(
        color: Color.primary.opacity(0.08),
        radius: 8,
        x: 0,
        y: 2
    )

    static let elevated = AppShadow(
        color: Color.primary.opacity(0.15),
        radius: 12,
        x: 0,
        y: 4
    )

    static let floating = AppShadow(
        color: Color.primary.opacity(0.2),
        radius: 16,
        x: 0,
        y: 6
    )
}

// MARK: - Card View Modifier

struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppCornerRadius.large
    var shadow: AppShadow = .card
    var hasBorder: Bool = false
    var borderColor: Color = Color.primary.opacity(0.1)
    var backgroundColor: Color = Color(.secondarySystemBackground)

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
            .overlay(
                Group {
                    if hasBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    }
                }
            )
    }
}

// MARK: - Dashed Card View Modifier

struct DashedCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppCornerRadius.large
    var dashColor: Color = Color.secondary.opacity(0.4)
    var lineWidth: CGFloat = 2
    var dash: [CGFloat] = [8, 6]

    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemBackground).opacity(0.5))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(style: StrokeStyle(lineWidth: lineWidth, dash: dash))
                    .foregroundColor(dashColor)
            )
    }
}

// MARK: - Gradient Card View Modifier

struct GradientCardModifier: ViewModifier {
    var colors: [Color]
    var cornerRadius: CGFloat = AppCornerRadius.xl
    var hasBorder: Bool = true
    var borderColor: Color = Color.appTheme.opacity(0.3)

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(cornerRadius)
            .overlay(
                Group {
                    if hasBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    }
                }
            )
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(
        cornerRadius: CGFloat = AppCornerRadius.large,
        shadow: AppShadow = .card,
        hasBorder: Bool = false,
        borderColor: Color = Color.primary.opacity(0.1),
        backgroundColor: Color = Color(.secondarySystemBackground)
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
        dashColor: Color = Color.secondary.opacity(0.4)
    ) -> some View {
        modifier(DashedCardModifier(
            cornerRadius: cornerRadius,
            dashColor: dashColor
        ))
    }

    func gradientCardStyle(
        colors: [Color] = [Color("appTheme").opacity(0.15), Color("appTheme").opacity(0.05)],
        cornerRadius: CGFloat = AppCornerRadius.xl,
        hasBorder: Bool = true,
        borderColor: Color = Color("appTheme").opacity(0.3)
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

            Text("Elevated Card")
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .cardStyle(shadow: .elevated)

            Text("Dashed Card")
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .dashedCardStyle()

            Text("Gradient Card")
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .gradientCardStyle()
        }
        .padding(AppSpacing.md)
    }
}
