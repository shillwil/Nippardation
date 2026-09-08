//
//  WizardComponents.swift
//  Nippardation
//
//  Shared Void building blocks for the plan wizard (Build) and the AI plan wizard:
//  selectable option cards, chips and square tiles, text and number wells,
//  the step heading, the footer (Back pill + one CTA) and the busy overlay.
//

import SwiftUI
import UIKit

// MARK: - Option card

/// Selectable panel: radius 12, panel + hairline-2.
/// Selected = panel-2 fill, 1pt plasma line, plasma check glyph top-right. Press: panel-2 fill.
struct WizardOptionCard<Content: View>: View {
    var isSelected: Bool
    var isEnabled: Bool = true
    var radius: CGFloat = VoidRadius.tile
    var checkInset: CGFloat = 10
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: VoidIcon.check.systemName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(VoidColor.plasma)
                            .padding(checkInset)
                            .accessibilityHidden(true)
                    }
                }
        }
        .buttonStyle(VoidPanelButtonStyle(
            radius: radius,
            line: isSelected ? VoidColor.plasma : VoidColor.hairline2,
            fill: isSelected ? VoidColor.panel2 : VoidColor.panel
        ))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Chip

/// Selectable chip: 36pt, radius 8, panel + hairline-2, chip label. Selected = panel-2 + plasma line + check.
struct WizardChip: View {
    let title: String
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: VoidIcon.check.systemName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(VoidColor.plasma)
                        .accessibilityHidden(true)
                }
                Text(title).voidChipLabel()
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
        }
        .buttonStyle(VoidPanelButtonStyle(
            radius: VoidRadius.control,
            line: isSelected ? VoidColor.plasma : VoidColor.hairline2,
            fill: isSelected ? VoidColor.panel2 : VoidColor.panel
        ))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Square tile

/// 44pt squared selector tile: plasma / on-plasma when selected, panel + hairline-2 otherwise.
struct WizardSquareTile: View {
    enum Style {
        /// Eyebrow-sm label (MON, TUE …).
        case eyebrow
        /// SF 17 semibold label (a count).
        case number
    }

    let label: String
    var isSelected: Bool
    var style: Style = .eyebrow
    var accessibilityLabel: String? = nil
    let action: () -> Void

    private var ink: Color { isSelected ? VoidColor.onPlasma : VoidColor.text }

    var body: some View {
        Button(action: action) {
            Group {
                switch style {
                case .eyebrow:
                    Text(label).voidEyebrowSm(ink)
                case .number:
                    Text(label).font(VoidFont.buttonLg).foregroundStyle(ink)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .frame(height: VoidSize.pill)
        }
        .buttonStyle(VoidPanelButtonStyle(
            radius: VoidRadius.tile,
            line: isSelected ? Color.clear : VoidColor.hairline2,
            fill: isSelected ? VoidColor.plasma : VoidColor.panel,
            pressedFill: isSelected ? VoidColor.plasma : VoidColor.panel2
        ))
        .accessibilityLabel(accessibilityLabel ?? label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Text wells

/// Multi-line text well: panel-2 fill, radius 12, SF 15, grows between `lines`.
struct WizardTextArea: View {
    let placeholder: String
    @Binding var text: String
    var lines: ClosedRange<Int> = 3...5

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .font(VoidFont.body)
            .foregroundStyle(VoidColor.text)
            .lineLimit(lines)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2, fill: VoidColor.panel2)
    }
}

/// Integer well: centered digits, number pad.
struct WizardIntField: View {
    let placeholder: String
    @Binding var value: Int
    var height: CGFloat = VoidSize.pill

    var body: some View {
        TextField(placeholder, value: $value, format: .number)
            .font(VoidFont.body)
            .foregroundStyle(VoidColor.text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .frame(height: height)
            .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2, fill: VoidColor.panel2)
    }
}

/// Decimal well: centered digits, decimal pad.
struct WizardDecimalField: View {
    let placeholder: String
    @Binding var value: Double
    var height: CGFloat = VoidSize.pill

    var body: some View {
        TextField(placeholder, value: $value, format: .number)
            .font(VoidFont.body)
            .foregroundStyle(VoidColor.text)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .frame(height: height)
            .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2, fill: VoidColor.panel2)
    }
}

// MARK: - Glyph square

/// 36pt squared glyph well (radius 10, panel-2) for list rows.
struct WizardGlyphSquare: View {
    let icon: VoidIcon
    var color: Color = VoidColor.text

    var body: some View {
        Image(systemName: icon.systemName)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(color)
            .frame(width: VoidSize.avatar, height: VoidSize.avatar)
            .background(VoidColor.panel2)
            .clipShape(RoundedRectangle(cornerRadius: VoidRadius.avatar, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - Headings and labels

/// Step heading: SF 20 bold title + SF 13 text-2 caption.
struct WizardStepHeading: View {
    let title: String
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s1) {
            Text(title)
                .font(VoidFont.title)
                .foregroundStyle(VoidColor.text)
            if let caption {
                Text(caption)
                    .font(VoidFont.caption)
                    .foregroundStyle(VoidColor.text2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, VoidSpace.s1)
    }
}

/// Eyebrow-sm section label with an optional trailing readout, nudged 4pt so it sits on the 20pt text grid
/// inside a 16pt card column.
struct WizardSectionLabel: View {
    let title: String
    var trailing: String? = nil
    var trailingColor: Color = VoidColor.text2

    var body: some View {
        HStack {
            Text(title).voidEyebrowSm()
            Spacer()
            if let trailing {
                Text(trailing).voidEyebrowSm(trailingColor)
            }
        }
        .padding(.horizontal, VoidSpace.s1)
    }
}

/// Helper text: SF 13 text-2.
struct WizardHelperText: View {
    let text: String
    var color: Color = VoidColor.text2

    var body: some View {
        Text(text)
            .font(VoidFont.caption)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, VoidSpace.s1)
    }
}

// MARK: - Footer

/// Wizard footer: an optional Back pill and the one CTA for the screen.
struct WizardFooter<CTA: View>: View {
    var showBack: Bool
    let onBack: () -> Void
    @ViewBuilder let cta: () -> CTA

    var body: some View {
        HStack(spacing: 10) {
            if showBack {
                VoidPillButton(title: "Back", action: onBack)
                    .frame(width: 112)
            }
            cta()
        }
        .padding(.horizontal, VoidSpace.insetCard)
        .padding(.top, VoidSpace.s3)
        .padding(.bottom, VoidSpace.s4)
    }
}

// MARK: - Busy overlay

/// Scrim + panel: eyebrow, optional message (SF 15), plasma spinner, optional Cancel pill.
struct WizardBusyOverlay: View {
    let eyebrow: String
    var message: String? = nil
    var onCancel: (() -> Void)? = nil

    var body: some View {
        ZStack {
            VoidColor.scrim.ignoresSafeArea()
            VStack(spacing: VoidSpace.s4) {
                Text(eyebrow).voidEyebrow()
                if let message {
                    Text(message)
                        .font(VoidFont.body)
                        .foregroundStyle(VoidColor.text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ProgressView()
                    .tint(VoidColor.plasma)
                if let onCancel {
                    VoidPillButton(title: "Cancel", action: onCancel)
                }
            }
            .padding(VoidSpace.s5)
            .frame(maxWidth: 320)
            .voidPanel(radius: VoidRadius.tabBar, line: VoidColor.hairline2)
            .padding(.horizontal, VoidSpace.s6)
        }
        .accessibilityAddTraits(.isModal)
    }
}

// MARK: - Previews

#Preview("Wizard components") {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        VStack(spacing: 16) {
            WizardStepHeading(title: "The basics", caption: "Name the plan and pick the days")
            WizardSectionLabel(title: "Duration", trailing: "08 WK")
            HStack(spacing: 10) {
                WizardOptionCard(isSelected: true, action: {}) {
                    Text("Ongoing").font(VoidFont.bodyStrong).foregroundStyle(VoidColor.text)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                }
                WizardOptionCard(isSelected: false, action: {}) {
                    Text("Fixed length").font(VoidFont.bodyStrong).foregroundStyle(VoidColor.text)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                }
            }
            HStack(spacing: 8) {
                WizardChip(title: "Push Pull Legs", isSelected: true) {}
                WizardChip(title: "Upper Lower", isSelected: false) {}
            }
            HStack(spacing: 8) {
                WizardSquareTile(label: "MON", isSelected: true) {}
                WizardSquareTile(label: "TUE", isSelected: false) {}
                WizardSquareTile(label: "4", isSelected: true, style: .number) {}
            }
            WizardTextArea(placeholder: "Anything specific", text: .constant(""))
            HStack(spacing: 8) {
                WizardIntField(placeholder: "Sets", value: .constant(3))
                WizardDecimalField(placeholder: "Weight", value: .constant(135))
            }
            WizardFooter(showBack: true, onBack: {}) {
                VoidCTAButton(title: "Continue") {}
            }
        }
        .padding(16)
    }
}

#Preview("Busy overlay") {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        WizardBusyOverlay(eyebrow: "Generating", message: "Selecting exercises", onCancel: {})
    }
}
