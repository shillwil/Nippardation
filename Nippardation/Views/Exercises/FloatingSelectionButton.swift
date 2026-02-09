//
//  FloatingSelectionButton.swift
//  Nippardation
//
//  Floating "Add N Exercises" button shown when exercises are selected
//

import SwiftUI

struct FloatingSelectionButton: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                Text("Add \(count) Exercise\(count == 1 ? "" : "s")")
            }
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.appTheme)
            .cornerRadius(AppCornerRadius.xl)
            .shadow(color: Color.appTheme.opacity(0.3), radius: 8, y: 4)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        FloatingSelectionButton(count: 3, action: {})
    }
}
