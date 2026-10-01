//
//  ShrinkThenWrapText.swift
//  Nippardation
//
//  A line of text that shrinks toward a floor to stay on one line, and wraps onto a second
//  line only when even the floor isn't enough. SwiftUI's own `lineLimit(2)` with
//  `minimumScaleFactor` works the other way round: it wraps first, and shrinks only once two
//  lines are full. Style it like a Text (font, tracking, case, colour); give it a bounded
//  width, as a list row does.
//

import SwiftUI

struct ShrinkThenWrapText: View {
    private let text: String
    private let minimumScaleFactor: CGFloat

    init(_ text: String, minimumScaleFactor: CGFloat = 0.7) {
        self.text = text
        self.minimumScaleFactor = minimumScaleFactor
    }

    var body: some View {
        if text.contains(where: \.isNewline) {
            // One line would hide everything after the break.
            twoLines
        } else {
            // ViewThatFits takes the first child whose ideal width fits. The one-line text
            // reports the width it needs at the floor, so it wins whenever it fits once shrunk.
            ViewThatFits(in: .horizontal) {
                WidthAtScale(scale: minimumScaleFactor) {
                    Text(text)
                        .lineLimit(1)
                        .minimumScaleFactor(minimumScaleFactor)
                    Text(text)
                        .tracking(0)
                        .hidden()
                        .accessibilityHidden(true)
                }
                twoLines
            }
        }
    }

    private var twoLines: some View {
        Text(text)
            .lineLimit(2)
            .minimumScaleFactor(minimumScaleFactor)
    }
}

/// Lays out the one-line text, but answers an ideal-width query with the width that text needs
/// at `scale`. Shrinking scales the glyphs and not the letter spacing (`tracking`), so the
/// hidden second child, the same text with no letter spacing, separates the part that shrinks
/// from the part that doesn't.
private struct WidthAtScale: Layout {
    let scale: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let full = subviews[0].sizeThatFits(proposal)
        guard proposal.width == nil else { return full }
        let glyphs = subviews[1].sizeThatFits(proposal).width
        let spacing = max(full.width - glyphs, 0)
        // A point of slack, so text right at the floor wraps instead of rounding into "…".
        return CGSize(width: (glyphs * scale + spacing).rounded(.up) + 1, height: full.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            subview.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
        }
    }
}
