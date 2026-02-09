//
//  Animations.swift
//  Nippardation
//
//  Standard animation presets for the design system
//

import SwiftUI

enum AppAnimation {
    /// Standard spring animation for card interactions
    static let cardSpring = Animation.spring(duration: 0.3, bounce: 0.15)

    /// Ease-out for content appearing
    static let contentAppear = Animation.easeOut(duration: 0.25)

    /// Slow pulse for empty state animations
    static let pulse = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
}

// MARK: - Card Appear Modifier

struct CardAppearModifier: ViewModifier {
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 8)
            .onAppear {
                withAnimation(AppAnimation.contentAppear) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func cardAppearAnimation() -> some View {
        modifier(CardAppearModifier())
    }
}
