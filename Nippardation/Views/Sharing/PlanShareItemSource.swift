//
//  PlanShareItemSource.swift
//  Nippardation
//
//  Gives the system share sheet a preview card (plan name · days · minutes) alongside the link.
//

import UIKit
import LinkPresentation

final class PlanShareItemSource: NSObject, UIActivityItemSource {
    let url: URL
    let title: String
    let subtitle: String?

    init(url: URL, title: String, subtitle: String? = nil) {
        self.url = url
        self.title = title
        self.subtitle = subtitle
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        subtitle.map { "\(title) · \($0)" } ?? title
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        metadata.url = url
        metadata.title = subtitle.map { "\(title) · \($0)" } ?? title
        if let icon = UIImage(named: "AppIcon") ?? UIImage(systemName: "dumbbell.fill") {
            metadata.iconProvider = NSItemProvider(object: icon)
        }
        return metadata
    }
}

extension PlanShareItemSource {
    /// Preview subtitle for a plan: "4 days · ~60 min"
    static func subtitle(for program: Program) -> String {
        var parts: [String] = []
        let days = program.workouts.isEmpty ? program.daysPerWeek : program.workouts.count
        parts.append("\(days) \(days == 1 ? "day" : "days")")
        let minutes = program.workouts.compactMap { $0.template?.estimatedDurationMinutes }.filter { $0 > 0 }
        if !minutes.isEmpty {
            parts.append("~\(minutes.reduce(0, +) / minutes.count) min")
        }
        return parts.joined(separator: " · ")
    }

    /// Preview subtitle for a single workout: "6 exercises · ~55 min"
    static func subtitle(for template: Template) -> String {
        var parts = ["\(template.exerciseCount) \(template.exerciseCount == 1 ? "exercise" : "exercises")"]
        if template.estimatedDurationMinutes > 0 {
            parts.append("~\(template.estimatedDurationMinutes) min")
        }
        return parts.joined(separator: " · ")
    }
}
