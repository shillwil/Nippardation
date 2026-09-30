//
//  DaySelectorGrid.swift
//  Nippardation
//
//  The plan wizard's training days: seven system toggle buttons, Monday to Sunday.
//

import SwiftUI

struct DaySelectorGrid: View {
    @Binding var selectedDays: Set<Int>

    private let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: VoidSpace.s2) {
                ForEach(0..<7, id: \.self) { index in
                    let isSelected = selectedDays.contains(index)
                    Toggle(isOn: binding(for: index)) {
                        // One letter per day so seven system buttons share a phone-width row;
                        // VoiceOver reads the full day name.
                        Text(String(VoidFormat.weekStripLabels[index].prefix(1)))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            // With the button's own padding this keeps the 44pt minimum hit target.
                            .frame(maxWidth: .infinity, minHeight: 30)
                            // On fills with plasma, which needs the on-plasma ink (the default is white).
                            .foregroundStyle(isSelected ? VoidColor.onPlasma : VoidColor.text)
                    }
                    .toggleStyle(.button)
                    .accessibilityLabel(dayNames[index])
                }
            }
            .buttonBorderShape(.roundedRectangle(radius: VoidRadius.tile))
            .tint(VoidColor.plasma)

            WizardHelperText(text: "\(selectedDays.count) day\(selectedDays.count == 1 ? "" : "s") selected")
        }
    }

    private func binding(for index: Int) -> Binding<Bool> {
        Binding(
            get: { selectedDays.contains(index) },
            set: { isOn in
                if isOn {
                    selectedDays.insert(index)
                } else {
                    selectedDays.remove(index)
                }
            }
        )
    }
}

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        DaySelectorGrid(selectedDays: .constant([0, 2, 4]))
            .padding(VoidSpace.insetCard)
    }
}
