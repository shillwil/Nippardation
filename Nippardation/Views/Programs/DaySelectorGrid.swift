//
//  DaySelectorGrid.swift
//  Nippardation
//
//  Seven 44pt squared day tiles for the plan wizard (Mon … Sun).
//

import SwiftUI

struct DaySelectorGrid: View {
    @Binding var selectedDays: Set<Int>

    private let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: VoidSpace.s2) {
                ForEach(0..<7, id: \.self) { index in
                    WizardSquareTile(
                        label: VoidFormat.weekStripLabels[index],
                        isSelected: selectedDays.contains(index),
                        accessibilityLabel: dayNames[index]
                    ) {
                        if selectedDays.contains(index) {
                            selectedDays.remove(index)
                        } else {
                            selectedDays.insert(index)
                        }
                    }
                }
            }

            WizardHelperText(text: "\(selectedDays.count) day\(selectedDays.count == 1 ? "" : "s") selected")
        }
    }
}

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        DaySelectorGrid(selectedDays: .constant([0, 2, 4]))
            .padding(VoidSpace.insetCard)
    }
}
