//
//  NewTemplateCard.swift
//  Nippardation
//
//  Dashed card for creating a new template in the grid
//

import SwiftUI

struct NewTemplateCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary)

                Text("New Template")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 140)
            .dashedCardStyle()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NewTemplateCard(onTap: {})
        .frame(width: 170)
        .padding()
}
