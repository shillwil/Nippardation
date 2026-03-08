//
//  EnvironmentBanner.swift
//  Nippardation
//

import SwiftUI

struct EnvironmentBannerModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if STAGING
        content.overlay(alignment: .top) {
            Text("STAGING")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, AppSpacing.xxs)
                .background(Color.orange)
                .clipShape(Capsule())
                .padding(.top, AppSpacing.xxs)
                .allowsHitTesting(false)
        }
        #else
        content
        #endif
    }
}

extension View {
    func environmentBanner() -> some View {
        modifier(EnvironmentBannerModifier())
    }
}
