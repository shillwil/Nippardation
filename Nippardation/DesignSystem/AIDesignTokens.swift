//
//  AIDesignTokens.swift
//  Nippardation
//
//  The one AI-specific piece left in Void: the sparkle heading. AI is not a separate colour —
//  plasma is the one action colour — and the AI screens use the same system buttons, pickers
//  and progress views as everything else.
//

import SwiftUI

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
                    .accessibilityHidden(true)
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

// MARK: - Previews

#Preview("AI section header") {
    VStack(spacing: AppSpacing.md) {
        AISectionHeader("AI plan · generated in 07 s")
        AISectionHeader("Your goal", subtitle: "Choose your training focus")
    }
    .padding()
    .background(VoidColor.hull)
}
