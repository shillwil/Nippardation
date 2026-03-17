//
//  ShareActivityView.swift
//  Nippardation
//
//  UIActivityViewController wrapper for sharing URLs via the system share sheet
//

import SwiftUI

struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
