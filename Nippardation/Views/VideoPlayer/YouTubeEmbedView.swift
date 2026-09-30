//
//  YouTubeEmbedView.swift
//  Nippardation
//
//  Fallback demo for legacy hardcoded templates whose example is a YouTube <iframe>.
//  AVKit can't play YouTube, so this stays a WKWebView. Web media never starts without a
//  tap: once someone plays audible web video, WebKit takes a non-mixable audio session and
//  pauses their music, which is fine for a deliberate tap but never for an autoplay.
//

import SwiftUI
import WebKit

struct YouTubeEmbedView: UIViewRepresentable {
    let html: String

    /// True when `example` holds embed markup rather than a plain video URL.
    static func isEmbed(_ example: String) -> Bool {
        example.range(of: "<iframe", options: .caseInsensitive) != nil
    }

    static func makeConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all
        return config
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: Self.makeConfiguration())
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        let wrapped = """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
        body { margin: 0; padding: 0; background: transparent; display: flex; justify-content: center; align-items: center; height: 100vh; }
        iframe { width: 100%; height: 100%; border: none; border-radius: 12px; }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
        // YouTube's player refuses an embed that arrives with no Referer (error 153), and a page
        // loaded with no base URL sends none. YouTube asks WebView apps for an https origin
        // named after the app ID; the iframes' strict-origin-when-cross-origin policy sends it.
        let origin = URL(string: "https://" + (Bundle.main.bundleIdentifier ?? "com.shillwil.recess-fitness"))
        webView.loadHTMLString(wrapped, baseURL: origin)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
