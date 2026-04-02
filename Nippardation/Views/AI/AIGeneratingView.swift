//
//  AIGeneratingView.swift
//  Nippardation
//
//  Full-screen overlay shown during AI program generation
//

import SwiftUI

struct AIGeneratingView: View {
    let messageIndex: Int
    let messages: [String]
    let onCancel: () -> Void

    @State private var sparkleRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    AIColors.gradientStart.opacity(0.95),
                    AIColors.gradientEnd.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // Animated sparkles icon
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(sparkleRotation))
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                            sparkleRotation = 360
                        }
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            pulseScale = 1.15
                        }
                    }

                // Loading message
                VStack(spacing: AppSpacing.sm) {
                    Text("Generating Your Program")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(messages.indices.contains(messageIndex) ? messages[messageIndex] : "")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .animation(.easeInOut(duration: 0.3), value: messageIndex)
                        .id(messageIndex)
                }

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.2)

                Spacer()

                // Cancel button
                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(.white.opacity(0.15))
                        .cornerRadius(AppCornerRadius.medium)
                }
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    AIGeneratingView(
        messageIndex: 1,
        messages: ["Analyzing your goals...", "Selecting exercises...", "Building your program..."],
        onCancel: {}
    )
}
