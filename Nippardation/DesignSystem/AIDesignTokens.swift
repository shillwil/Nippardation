//
//  AIDesignTokens.swift
//  Nippardation
//
//  Design tokens and reusable components for AI-powered features
//

import SwiftUI

// MARK: - AI Color Palette

enum AIColors {
    static let gradientStart = Color.purple
    static let gradientEnd = Color.indigo
    static let accent = Color.purple

    static var gradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var subtleGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart.opacity(0.15), gradientEnd.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - AI Gradient Button

struct AIGradientButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false

    init(_ title: String, icon: String? = "sparkles", isDisabled: Bool = false, action: @escaping () -> Void) {
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
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .foregroundColor(.white)
            .background(
                isDisabled
                    ? AnyShapeStyle(Color.gray)
                    : AnyShapeStyle(AIColors.gradient)
            )
            .cornerRadius(AppCornerRadius.medium)
        }
        .disabled(isDisabled)
    }
}

// MARK: - AI Step Indicator

struct AIStepIndicator: View {
    let totalSteps: Int
    let currentStep: Int

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? AnyShapeStyle(AIColors.gradient) : AnyShapeStyle(Color.secondary.opacity(0.3)))
                    .frame(width: step == currentStep ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: currentStep)
            }
        }
    }
}

// MARK: - AI Card Style

struct AIGradientCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppCornerRadius.xl

    func body(content: Content) -> some View {
        content
            .background(AIColors.subtleGradient)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [AIColors.gradientStart.opacity(0.4), AIColors.gradientEnd.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
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
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AIColors.gradient)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: "sparkles")
                .font(.caption2)
            Text("\(remaining)/\(limit) generations")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .foregroundColor(remaining > 0 ? AIColors.accent : .red)
        .background(
            (remaining > 0 ? AIColors.accent : Color.red).opacity(0.12)
        )
        .cornerRadius(AppCornerRadius.small)
    }
}

// MARK: - Previews

#Preview("AI Gradient Button") {
    VStack(spacing: AppSpacing.md) {
        AIGradientButton("Generate Program") {}
        AIGradientButton("No Generations Left", isDisabled: true) {}
    }
    .padding()
}

#Preview("AI Step Indicator") {
    VStack(spacing: AppSpacing.lg) {
        AIStepIndicator(totalSteps: 4, currentStep: 0)
        AIStepIndicator(totalSteps: 4, currentStep: 1)
        AIStepIndicator(totalSteps: 4, currentStep: 2)
        AIStepIndicator(totalSteps: 4, currentStep: 3)
    }
}

#Preview("AI Components") {
    VStack(spacing: AppSpacing.md) {
        AISectionHeader("Your Goal", subtitle: "Choose your training focus")
        AIQuotaBadge(remaining: 2, limit: 3)
        AIQuotaBadge(remaining: 0, limit: 3)

        Text("AI Gradient Card")
            .frame(maxWidth: .infinity)
            .padding()
            .aiGradientCardStyle()
    }
    .padding()
}
