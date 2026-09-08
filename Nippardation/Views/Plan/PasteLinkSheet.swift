//
//  PasteLinkSheet.swift
//  Nippardation
//
//  Paste a plan link (recess://plan/<id>, https://recess.fit/p/<id>, nippardation://share/<id>).
//  Opening hands the URL back to the presenter, which routes it once the sheet is down.
//

import SwiftUI
import UIKit

struct PasteLinkSheet: View {
    /// Called with a valid share link right before the sheet dismisses.
    let onOpen: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var canPaste = false
    @State private var pasteMissed = false

    private var url: URL? { Self.shareURL(from: text) }

    var body: some View {
        VoidSheetContainer {
            VStack(alignment: .leading, spacing: 0) {
                Text("Paste a link").voidEyebrow()

                Text("recess.fit/p/… or recess://plan/…")
                    .font(VoidFont.caption2)
                    .foregroundStyle(VoidColor.text2)
                    .padding(.top, 6)

                VoidTextField(
                    placeholder: "https://recess.fit/p/…",
                    text: $text,
                    icon: .link,
                    keyboard: .URL,
                    autocapitalization: .never
                )
                .padding(.top, 18)
                .onSubmit { open() }

                if canPaste {
                    VoidPillButton(title: "Paste") { paste() }
                        .padding(.top, 10)
                }

                if pasteMissed {
                    Text("The clipboard has no plan link.")
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text3)
                        .padding(.top, 8)
                }

                VoidCTAButton(title: "Open", isEnabled: url != nil) { open() }
                    .padding(.top, 10)
            }
        }
        .voidSheet()
        .presentationDetents([.medium])
        .onAppear {
            let board = UIPasteboard.general
            canPaste = board.hasStrings || board.hasURLs
        }
    }

    // MARK: - Actions

    private func paste() {
        let board = UIPasteboard.general
        let candidate = board.string ?? board.url?.absoluteString ?? ""
        if Self.shareURL(from: candidate) != nil {
            text = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            pasteMissed = false
        } else {
            pasteMissed = true
        }
    }

    private func open() {
        guard let url else { return }
        onOpen(url)
        dismiss()
    }

    // MARK: - Parsing

    /// Accepts any supported link; a bare "recess.fit/p/…" gets an https scheme.
    static func shareURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if DeepLinkRouter.isShareLink(trimmed), let url = URL(string: trimmed) {
            return url
        }
        if !trimmed.contains("://") {
            let prefixed = "https://" + trimmed
            if DeepLinkRouter.isShareLink(prefixed), let url = URL(string: prefixed) {
                return url
            }
        }
        return nil
    }
}

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
    }
    .sheet(isPresented: .constant(true)) {
        PasteLinkSheet { _ in }
    }
}
