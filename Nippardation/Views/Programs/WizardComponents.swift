//
//  WizardComponents.swift
//  Nippardation
//
//  Shared building blocks for the plan wizard (Build) and the AI plan wizard: the step chrome
//  (title, Cancel, step progress, one pinned primary action), Void colours for the grouped form
//  rows, the day tile, text and number wells, and the small labels.
//
//  Both wizards push their steps onto their own NavigationStack, so the system back button and
//  edge swipe step back; the choices themselves are system pickers, toggles and steppers.
//

import SwiftUI
import UIKit

// MARK: - Step chrome

extension View {
    /// The chrome every wizard step shares: an inline title, a Cancel that leaves the whole wizard,
    /// the step's progress, and its one primary action pinned to the bottom.
    ///
    /// - Parameters:
    ///   - step: The step's position, 0-based.
    ///   - onCancel: Dismisses the wizard. Leaving throws away what was picked, so it is a Cancel.
    func wizardStep<Action: View>(
        _ title: String,
        step: Int,
        of totalSteps: Int,
        onCancel: @escaping () -> Void,
        @ViewBuilder action: () -> Action
    ) -> some View {
        modifier(WizardStepChrome(
            title: title,
            step: step,
            totalSteps: totalSteps,
            onCancel: onCancel,
            action: action()
        ))
    }

    /// Void colours for the rows of a grouped wizard form: panel fill, hairline separators.
    func wizardFormRows() -> some View {
        self
            .listRowBackground(VoidColor.panel)
            .listRowSeparatorTint(VoidColor.hairline)
    }
}

/// See `View.wizardStep(_:step:of:onCancel:action:)`.
///
/// On iOS 26 the step also reads "Step n of total" as the navigation subtitle, and the bottom bar is a
/// `safeAreaBar`, so rows scroll under it with the system scroll-edge effect. Before iOS 26 the bar sits
/// on an opaque hull strip, so rows scroll out of sight instead of behind a floating button.
private struct WizardStepChrome<Action: View>: ViewModifier {
    let title: String
    let step: Int
    let totalSteps: Int
    let onCancel: () -> Void
    let action: Action

    func body(content: Content) -> some View {
        let titled = content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: onCancel)
                }
            }

        if #available(iOS 26.0, *) {
            titled
                .navigationSubtitle("Step \(step + 1) of \(totalSteps)")
                .safeAreaBar(edge: .bottom) { bar }
        } else {
            titled
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bar.background(VoidColor.hull.ignoresSafeArea(edges: .bottom))
                }
        }
    }

    /// The step's progress above its primary action.
    private var bar: some View {
        VStack(spacing: VoidSpace.s3) {
            StepIndicator(totalSteps: totalSteps, currentStep: step)
            action
        }
        .padding(.horizontal, VoidSpace.insetCard)
        .padding(.top, VoidSpace.s3)
        .padding(.bottom, VoidSpace.s2)
    }
}

// MARK: - Text wells

/// Multi-line text well: panel-2 fill, radius 12, grows between `lines`.
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

/// Integer well: centered digits, number pad. The number pad has no return key, so the field puts
/// a Done button above the keyboard while it is being edited.
struct WizardIntField: View {
    let placeholder: String
    @Binding var value: Int
    /// Minimum height; the well grows with Dynamic Type.
    var height: CGFloat = VoidSize.pill

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, value: $value, format: .number)
            .font(VoidFont.body)
            .foregroundStyle(VoidColor.text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .focused($isFocused)
            .padding(.horizontal, 8)
            .frame(minHeight: height)
            .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2, fill: VoidColor.panel2)
            .keyboardDoneButton(isFocused: $isFocused)
    }
}

/// Decimal well: centered digits, decimal pad, with the same keyboard Done as `WizardIntField`.
struct WizardDecimalField: View {
    let placeholder: String
    @Binding var value: Double
    /// Minimum height; the well grows with Dynamic Type.
    var height: CGFloat = VoidSize.pill

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, value: $value, format: .number)
            .font(VoidFont.body)
            .foregroundStyle(VoidColor.text)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .focused($isFocused)
            .padding(.horizontal, 8)
            .frame(minHeight: height)
            .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2, fill: VoidColor.panel2)
            .keyboardDoneButton(isFocused: $isFocused)
    }
}

private extension View {
    /// A keyboard-toolbar Done that ends editing. Only the focused field contributes it, so a screen
    /// full of number wells still shows a single Done.
    func keyboardDoneButton(isFocused: FocusState<Bool>.Binding) -> some View {
        toolbar {
            if isFocused.wrappedValue {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isFocused.wrappedValue = false }
                }
            }
        }
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

// MARK: - Labels

/// Eyebrow-sm label with an optional trailing readout, nudged 4pt so it sits on the 20pt text grid
/// inside a 16pt card column. For content outside a list; list sections use their native header.
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

/// Helper text: text-2 caption.
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

// MARK: - Previews

#Preview("Wizard components") {
    NavigationStack {
        Form {
            Section {
                Toggle("Fixed length", isOn: .constant(true))
            } header: {
                Text("Length")
            }
            .wizardFormRows()

            Section {
                WizardHelperText(text: "2 days selected")
            }
            .listRowBackground(Color.clear)

            Section {
                WizardTextArea(placeholder: "Anything specific", text: .constant(""))
                HStack(spacing: 8) {
                    WizardIntField(placeholder: "Sets", value: .constant(3))
                    WizardDecimalField(placeholder: "Weight", value: .constant(135))
                }
            }
            .listRowBackground(Color.clear)
        }
        .voidScreen()
        .wizardStep("Basics", step: 0, of: 3, onCancel: {}) {
            VoidCTAButton(title: "Continue") {}
        }
    }
}
