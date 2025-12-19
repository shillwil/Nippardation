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
        // Read from scheme environment variables (set in Xcode scheme editor)
        guard let env = ProcessInfo.processInfo.environment["APP_ENVIRONMENT"],
              !env.isEmpty else {
            // Default to staging if not set
            return .staging
        }
        return env == "Production" ? .production : .staging
    }
}

struct AppConfiguration {
    static let shared = AppConfiguration()
    
    private init() {}
    
    var environment: AppEnvironment {
        return AppEnvironment.current
    }
    
    var baseURL: URL {
        guard let urlString = ProcessInfo.processInfo.environment["API_BASE_URL"],
              !urlString.isEmpty else {
            fatalError("API_BASE_URL not found in environment variables. Set it in Xcode Scheme > Run > Arguments > Environment Variables.")
        }

        guard let url = URL(string: urlString) else {
            fatalError("Invalid API_BASE_URL: \(urlString)")
        }

        return url
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
            return "com.shillwil.Nippardation"
        case .production:
            return "com.shillwil.Nippardation"
        }
    }
}
