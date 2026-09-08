//
//  FloatingSelectionButton.swift
//  Nippardation
//
//  Floating "Add (n)" CTA shown over the browser while exercises are selected.
//  A `VoidCTAButton` sized to its title; the one plasma fill on the picker.
//

import SwiftUI

struct FloatingSelectionButton: View {
    let count: Int
    let action: () -> Void

    private var title: String {
        "Add (\(count))"
    }

    var body: some View {
        VoidCTAButton(title: title, action: action)
            .frame(width: max(132, CGFloat(title.count) * 10 + 56))
    }
}

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        VStack {
            Spacer()
            FloatingSelectionButton(count: 3, action: {})
            FloatingSelectionButton(count: 12, action: {})
        }
        .padding(.bottom, 24)
    }
}
