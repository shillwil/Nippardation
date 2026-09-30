//
//  PasteLinkSheet.swift
//  Nippardation
//
//  Paste a plan link (recess://plan/<id>, https://recess.fit/p/<id>, nippardation://share/<id>).
//  Opening hands the URL back to the presenter, which routes it once the sheet is down.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PasteLinkSheet: View {
    /// Called with a valid share link right before the sheet dismisses.
    let onOpen: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var canPaste = false
    @State private var pasteMissed = false

    private var url: URL? { Self.shareURL(from: text) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("recess.fit/p/… or recess://plan/…")
                    .font(VoidFont.caption2)
                    .foregroundStyle(VoidColor.text2)

                VoidTextField(
                    placeholder: "https://recess.fit/p/…",
                    text: $text,
                    icon: .link,
                    keyboard: .URL,
                    autocapitalization: .never
                )
                .padding(.top, 12)
                .onSubmit { open() }

                if canPaste {
                    // The system Paste button reads the clipboard only when tapped, so iOS asks for
                    // no paste permission. It takes a URL as well as text: a share sheet's Copy puts
                    // a plan link on the clipboard as a URL only. Its white label is drawn by the
                    // system and must stay legible, so it sits on the dark Void ink rather than on plasma.
                    PasteButton(supportedContentTypes: [.url, .plainText]) { providers in
                        Task { @MainActor in
                            paste(await Self.linkText(from: providers) ?? "")
                        }
                    }
                    .labelStyle(.titleAndIcon)
                    .buttonBorderShape(.roundedRectangle(radius: VoidRadius.tile))
                    .tint(VoidColor.onPlasma)
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

                Spacer(minLength: 0)
            }
            .padding(.horizontal, VoidSpace.insetText)
            .padding(.top, VoidSpace.s2)
            .navigationTitle("Paste a link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
        }
        // One height, not resizable: no grabber (the system default hides it).
        .presentationDetents([.medium])
        .onAppear {
            // Checking what kind of data is on the clipboard doesn't read it, so iOS asks nothing here.
            let board = UIPasteboard.general
            canPaste = board.hasStrings || board.hasURLs
        }
    }

    // MARK: - Actions

    /// Takes what the Paste button delivered when it is a plan link.
    private func paste(_ candidate: String) {
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

    /// The text of what the Paste button delivered: the first item that loads as a URL (its absolute
    /// string) or, failing that, as text. Nil when nothing loads.
    static func linkText(from providers: [NSItemProvider]) async -> String? {
        for provider in providers {
            if let url = await provider.loadURL() {
                return url.absoluteString
            }
            if let text = await provider.loadString() {
                return text
            }
        }
        return nil
    }

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

// MARK: - Item loading

private extension NSItemProvider {
    /// The item as a URL, or nil when it has none or it fails to load.
    func loadURL() async -> URL? {
        guard canLoadObject(ofClass: URL.self) else { return nil }
        return await withCheckedContinuation { continuation in
            _ = loadObject(ofClass: URL.self) { url, _ in
                continuation.resume(returning: url)
            }
        }
    }

    /// The item as text, or nil when it has none or it fails to load.
    func loadString() async -> String? {
        guard canLoadObject(ofClass: String.self) else { return nil }
        return await withCheckedContinuation { continuation in
            _ = loadObject(ofClass: String.self) { text, _ in
                continuation.resume(returning: text)
            }
        }
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
