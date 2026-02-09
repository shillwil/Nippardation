//
//  TemplateEmptyStateView.swift
//  Nippardation
//
//  Animated empty state for the templates grid
//

import SwiftUI

struct TemplateEmptyStateView: View {
    let onCreate: () -> Void

    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            // Pulsing circle illustration
            ZStack {
                Circle()
                    .fill(Color.appTheme.opacity(0.08))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)

                Circle()
                    .fill(Color.appTheme.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.appTheme)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }

            // Text
            VStack(spacing: AppSpacing.xs) {
                Text("No Templates Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Templates define your workout structure — exercises, sets, reps, and rest times. Create one to get started.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            // CTA
            Button(action: onCreate) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Template")
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
    TemplateEmptyStateView(onCreate: {})
}
