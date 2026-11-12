//
//  AppConfiguration.swift
//  Nippardation
//
//  Created by Claude on 7/10/25.
//

import Foundation

enum AppEnvironment: String {
    case staging = "Staging"
    case production = "Production"

    static var current: AppEnvironment {
        #if STAGING
        return .staging
        #else
        return .production
        #endif
    }
}

struct AppConfiguration {
    static let shared = AppConfiguration()

    private init() {}

    var environment: AppEnvironment {
        return .current
    }

    var baseURL: URL {
        #if STAGING
        return URL(string: "https://recess-backend-staging.up.railway.app")!
        #else
        return URL(string: "https://recess-backend-production.up.railway.app")!
        #endif
    }

    var firebasePlistName: String {
        switch environment {
        case .staging:
            return "GoogleService-Info-Staging"
        case .production:
            return "GoogleService-Info-Prod"
        }
    }

    var appName: String {
        switch environment {
        case .staging:
            return "Nippardation (Staging)"
        case .production:
            return "Nippardation"
        }
    }

    var bundleIdentifier: String {
        switch environment {
        case .staging:
            return "com.shillwil.recess-fitness.staging"
        case .production:
            return "com.shillwil.recess-fitness"
        }
    }

    /// The scheme the backend puts on share links (`nippardation://share/<token>`).
    var shareURLScheme: String {
        "nippardation"
    }

    /// Suffix on the custom URL schemes this build registers (`URL_SCHEME_SUFFIX` in the build
    /// settings feeds Info.plist). Staging is its own app and installs beside production, so it
    /// claims `nippardation-staging://` and `recess-staging://` and leaves the plain schemes to
    /// the production app.
    var urlSchemeSuffix: String {
        switch environment {
        case .staging:
            return "-staging"
        case .production:
            return ""
        }
    }

    // When false, the AI program wizard hides the equipment selector and sends
    // every equipment type to the backend so Gemini has no equipment constraint.
    var sendEquipmentToAI: Bool {
        false
    }
}
