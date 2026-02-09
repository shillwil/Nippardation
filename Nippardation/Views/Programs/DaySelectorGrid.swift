//
//  DaySelectorGrid.swift
//  Nippardation
//
//  Seven-button day selector for the program wizard
//

import SwiftUI

struct DaySelectorGrid: View {
    @Binding var selectedDays: Set<Int>

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(0..<7, id: \.self) { index in
                    dayButton(index: index)
                }
            }

            Text("\(selectedDays.count) day\(selectedDays.count == 1 ? "" : "s") selected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func dayButton(index: Int) -> some View {
        let isSelected = selectedDays.contains(index)

        return Button {
            if isSelected {
                selectedDays.remove(index)
            } else {
                selectedDays.insert(index)
            }
        } label: {
            VStack(spacing: AppSpacing.xxs) {
                Text(days[index])
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? Color.appTheme.opacity(0.15) : Color(.tertiarySystemBackground))
            .foregroundColor(isSelected ? .appTheme : .primary)
            .cornerRadius(AppCornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DaySelectorGrid(selectedDays: .constant([0, 2, 4]))
        .padding()
}
