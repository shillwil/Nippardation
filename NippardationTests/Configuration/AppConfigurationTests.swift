//
//  AppConfigurationTests.swift
//  NippardationTests
//
//  Staging and production are separate apps (separate bundle IDs), so the values compiled into
//  AppConfiguration must agree with what the build settings and the Firebase plist say.
//

import Foundation
import Testing
@testable import Nippardation

struct AppConfigurationTests {

    private var appBundle: Bundle { Bundle(for: WorkoutManager.self) }

    @Test func bundleIdentifierMatchesTheBuiltApp() {
        #expect(appBundle.bundleIdentifier == AppConfiguration.shared.bundleIdentifier)
    }

    @Test func stagingAndProductionAreDifferentApps() {
        let config = AppConfiguration.shared
        switch config.environment {
        case .staging:
            #expect(config.bundleIdentifier == "com.shillwil.recess-fitness.staging")
            #expect(config.urlSchemeSuffix == "-staging")
        case .production:
            #expect(config.bundleIdentifier == "com.shillwil.recess-fitness")
            #expect(config.urlSchemeSuffix.isEmpty)
        }
    }

    /// Firebase registers one app entry per bundle ID; a plist for the wrong entry is a misconfiguration.
    @Test func firebasePlistIsForThisBundleIdentifier() throws {
        let name = AppConfiguration.shared.firebasePlistName
        let url = try #require(appBundle.url(forResource: name, withExtension: "plist"))
        let plist = try #require(NSDictionary(contentsOf: url))

        #expect(plist["BUNDLE_ID"] as? String == appBundle.bundleIdentifier)
    }
}
