//
//  ProgramWizardStep1.swift
//  Nippardation
//
//  Step 1 of the plan wizard: name, duration and training days.
//

import SwiftUI

struct ProgramWizardStep1: View {
    @ObservedObject var viewModel: ProgramEditorViewModel

    private var weeks: Binding<Int> {
        Binding(
            get: { viewModel.durationWeeks ?? 8 },
            set: { viewModel.durationWeeks = min(max($0, 1), 52) }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoidSpace.s6) {
                WizardStepHeading(title: "The basics", caption: "Name the plan and pick the days you train.")

                // Plan name
                VStack(alignment: .leading, spacing: VoidSpace.s2) {
                    WizardSectionLabel(title: "Plan name")
                    VoidTextField(placeholder: "e.g. Upper / Lower", text: $viewModel.name, icon: .edit)
                }

                // Duration
                VStack(alignment: .leading, spacing: VoidSpace.s2) {
                    WizardSectionLabel(title: "Duration")

                    HStack(spacing: 10) {
                        durationOption(
                            title: "Ongoing",
                            caption: "No end date",
                            isSelected: viewModel.isIndefinite
                        ) {
                            viewModel.isIndefinite = true
                        }
                        durationOption(
                            title: "Fixed length",
                            caption: "Ends after a set number of weeks",
                            isSelected: !viewModel.isIndefinite
                        ) {
                            viewModel.isIndefinite = false
                        }
                    }

                    if !viewModel.isIndefinite {
                        weeksRow
                    }
                }

                // Training days
                VStack(alignment: .leading, spacing: VoidSpace.s2) {
                    WizardSectionLabel(title: "Training days")
                    DaySelectorGrid(selectedDays: $viewModel.selectedDays)
                }
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.vertical, VoidSpace.s2)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Subviews

    private func durationOption(title: String, caption: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        WizardOptionCard(isSelected: isSelected, action: action) {
            VStack(alignment: .leading, spacing: VoidSpace.s1) {
                Text(title)
                    .font(VoidFont.bodyStrong)
                    .foregroundStyle(VoidColor.text)
                Text(caption)
                    .font(VoidFont.caption2)
                    .foregroundStyle(VoidColor.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 14)
            .padding(.trailing, 28)
            .padding(.vertical, 14)
        }
    }

    private var weeksRow: some View {
        HStack(spacing: VoidSpace.s3) {
            VStack(alignment: .leading, spacing: 2) {
                Text(VoidFormat.weeks(weeks.wrappedValue).capitalized)
                    .font(VoidFont.bodyStrong)
                    .monospacedDigit()
                    .foregroundStyle(VoidColor.text)
                Text("1 to 52 weeks")
                    .font(VoidFont.caption2)
                    .foregroundStyle(VoidColor.text2)
            }

            Spacer()

            // VoidIcon has no minus glyph; system "minus" used here (foundation gap).
            weekStepButton(
                icon: "minus",
                label: "Remove a week",
                enabled: weeks.wrappedValue > 1
            ) {
                weeks.wrappedValue -= 1
            }

            weekStepButton(
                icon: VoidIcon.plus.systemName,
                label: "Add a week",
                enabled: weeks.wrappedValue < 52
            ) {
                weeks.wrappedValue += 1
            }
        }
        .padding(14)
        .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2)
    }

    /// 32pt control chrome (same look as `VoidControlButton`) drawn inside a 44pt label so the whole
    /// 44pt square is tappable: a `.frame` applied outside a Button only pads layout, not the hit region.
    private func weekStepButton(icon: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: VoidRadius.control, style: .continuous)
                    .fill(VoidColor.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: VoidRadius.control, style: .continuous)
                            .strokeBorder(VoidColor.hairline2, lineWidth: 1)
                    )
                    .frame(width: VoidSize.control, height: VoidSize.control)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(VoidColor.text)
            }
            .frame(width: VoidSize.hitMin, height: VoidSize.hitMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidPlainButtonStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
        .accessibilityLabel(label)
    }
}

#Preview {
    ProgramWizardStep1(viewModel: ProgramEditorViewModel())
        .voidScreen()
        .withDependencies(.preview)
}
