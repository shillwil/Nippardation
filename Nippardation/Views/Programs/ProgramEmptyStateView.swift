//
//  ProgramEmptyStateView.swift
//  Nippardation
//
//  Empty state for the programs library
//

import SwiftUI

struct ProgramEmptyStateView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(Color.appTheme.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 48))
                    .foregroundColor(.appTheme)
            }

            // Text
            VStack(spacing: AppSpacing.xs) {
                Text("Your Shelf is Empty")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create your first program to organize your training with structured workout rotations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            // CTA
            Button(action: onCreate) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Program")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ProgramEmptyStateView(onCreate: {})
}
