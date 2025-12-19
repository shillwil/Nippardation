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
        // Check environment variable first (for debug builds via Xcode)
        if let urlString = ProcessInfo.processInfo.environment["API_BASE_URL"],
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            return url
        }

        // Fallback for production/TestFlight builds
        #if DEBUG
        fatalError("API_BASE_URL not found. Set it in Xcode Scheme > Run > Arguments > Environment Variables.")
        #else
        // Production URL for archived builds
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
            return "com.shillwil.Nippardation"
        case .production:
            return "com.shillwil.Nippardation"
        }
    }
}
