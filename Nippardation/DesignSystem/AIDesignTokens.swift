//
//  AIDesignTokens.swift
//  Nippardation
//
//  Tokens and components for AI-powered features, restyled to Void.
//  AI is not a separate colour any more: plasma is the one action colour and there are no gradients.
//  The types keep their names so existing screens compile; `AIColors.gradient` is now flat plasma.
//

import SwiftUI

// MARK: - AI Palette (flat plasma)

enum AIColors {
    static let gradientStart = VoidColor.plasma
    static let gradientEnd = VoidColor.plasma
    static let accent = VoidColor.plasma

    /// Flat plasma. Kept as a `LinearGradient` so `.foregroundStyle(AIColors.gradient)` still compiles.
    static var gradient: LinearGradient {
        LinearGradient(colors: [VoidColor.plasma, VoidColor.plasma], startPoint: .leading, endPoint: .trailing)
    }

    /// Flat panel-2. Kept for the same reason.
    static var subtleGradient: LinearGradient {
        LinearGradient(colors: [VoidColor.panel2, VoidColor.panel2], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - AI Primary Button (the one plasma action on an AI screen)

struct AIGradientButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false

    init(_ title: String, icon: String? = VoidIcon.sparkle.systemName, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(VoidFont.buttonLg)
            }
            .foregroundStyle(VoidColor.onPlasma)
            .frame(maxWidth: .infinity)
            .frame(height: VoidSize.cta)
            .background(VoidColor.plasma)
            .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
        }
        .buttonStyle(VoidScaleButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

// MARK: - AI Step Indicator (squared marks)

struct AIStepIndicator: View {
    let totalSteps: Int
    let currentStep: Int

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(step <= currentStep ? VoidColor.plasma : VoidColor.track)
                    .frame(width: step == currentStep ? 24 : 8, height: 4)
                    .animation(.easeOut(duration: 0.12), value: currentStep)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep + 1) of \(totalSteps)")
    }
}

// MARK: - AI Card Style (flat panel)

struct AIGradientCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppCornerRadius.xl

    func body(content: Content) -> some View {
        content
            .background(VoidColor.panel)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(VoidColor.hairline2, lineWidth: 1)
            )
    }
}

extension View {
    func aiGradientCardStyle(cornerRadius: CGFloat = AppCornerRadius.xl) -> some View {
        modifier(AIGradientCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - AI Section Header

struct AISectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: VoidIcon.sparkle.systemName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(VoidColor.plasma)
                Text(title)
                    .voidEyebrow(VoidColor.text)
            }

            if let subtitle {
                Text(subtitle)
                    .font(VoidFont.body)
                    .foregroundStyle(VoidColor.text2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Quota Badge

struct AIQuotaBadge: View {
    let remaining: Int
    let limit: Int

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: VoidIcon.sparkle.systemName)
                .font(.system(size: 12, weight: .semibold))
            Text("\(VoidFormat.pad2(remaining)) / \(VoidFormat.pad2(limit)) LEFT")
                .voidChipLabel(remaining > 0 ? VoidColor.text : VoidColor.warning)
        }
        .foregroundStyle(remaining > 0 ? VoidColor.text : VoidColor.warning)
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .frame(height: VoidSize.chip)
        .voidPanel(radius: VoidRadius.control, line: VoidColor.hairline2)
    }
}

// MARK: - Previews

#Preview("AI Button") {
    VStack(spacing: AppSpacing.md) {
        AIGradientButton("Generate plan") {}
        AIGradientButton("No generations left", isDisabled: true) {}
    }
    .padding()
    .background(VoidColor.hull)
}

#Preview("AI Components") {
    VStack(spacing: AppSpacing.md) {
        AIStepIndicator(totalSteps: 4, currentStep: 1)
        AISectionHeader("Your goal", subtitle: "Choose your training focus")
        AIQuotaBadge(remaining: 2, limit: 3)
        AIQuotaBadge(remaining: 0, limit: 3)
        Text("AI card").frame(maxWidth: .infinity).padding().aiGradientCardStyle()
    }
    .padding()
    .foregroundStyle(VoidColor.text)
    .background(VoidColor.hull)
}
