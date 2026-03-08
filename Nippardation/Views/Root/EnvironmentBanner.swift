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
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.orange)
                .clipShape(Capsule())
                .padding(.top, 2)
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
