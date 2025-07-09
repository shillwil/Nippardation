//
//  WebViewRepresentable.swift
//  Nippardation
//
//  Created by Alex Shillingford on 7/8/25.
//

import SwiftUI
import WebKit

struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Updates handled in the main view
    }
}
