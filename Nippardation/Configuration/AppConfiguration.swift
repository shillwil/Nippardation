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
            return "com.shillwil.recess-fitness"
        case .production:
            return "com.shillwil.recess-fitness"
        }
    }

    var shareURLScheme: String {
        "nippardation"
    }
}
