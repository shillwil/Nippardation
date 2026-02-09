//
//  TabBarConfiguration.swift
//  Nippardation
//
//  Tab bar configuration for the bottom navigation
//

import SwiftUI

/// Defines the 5 bottom tabs for the main navigation
enum AppTab: String, CaseIterable, Hashable {
    case home
    case programs
    case templates
    case history
    case profile

    var label: String {
        switch self {
        case .home: return "Home"
        case .programs: return "Programs"
        case .templates: return "Templates"
        case .history: return "History"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .programs: return "list.bullet.clipboard"
        case .templates: return "doc.text"
        case .history: return "clock.arrow.circlepath"
        case .profile: return "person"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .programs: return "list.bullet.clipboard.fill"
        case .templates: return "doc.text.fill"
        case .history: return "clock.arrow.circlepath"
        case .profile: return "person.fill"
        }
    }
}
