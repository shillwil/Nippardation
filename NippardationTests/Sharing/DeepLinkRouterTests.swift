//
//  DeepLinkRouterTests.swift
//  NippardationTests
//
//  Tests for DeepLinkRouter URL parsing
//

import Testing
import Foundation
@testable import Nippardation

@Suite struct DeepLinkRouterTests {

    // MARK: - Token Extraction (static, no MainActor needed)

    @Test func extractsTokenFromValidShareURL() {
        let url = URL(string: "nippardation://share/abc123")!
        let token = DeepLinkRouter.extractShareToken(from: url)
        #expect(token == "abc123")
    }

    @Test func extractsTokenWithLongAlphanumericToken() {
        let url = URL(string: "nippardation://share/a3Bf9kLm2xQz")!
        let token = DeepLinkRouter.extractShareToken(from: url)
        #expect(token == "a3Bf9kLm2xQz")
    }

    @Test func returnsNilForWrongScheme() {
        let url = URL(string: "https://share/abc123")!
        let token = DeepLinkRouter.extractShareToken(from: url)
        #expect(token == nil)
    }

    @Test func returnsNilForMissingToken() {
        let url = URL(string: "nippardation://share/")!
        let token = DeepLinkRouter.extractShareToken(from: url)
        #expect(token == nil)
    }

    @Test func returnsNilForWrongHost() {
        let url = URL(string: "nippardation://other/abc123")!
        let token = DeepLinkRouter.extractShareToken(from: url)
        #expect(token == nil)
    }

    @Test func returnsNilForEmptyURL() {
        let url = URL(string: "nippardation://")!
        let token = DeepLinkRouter.extractShareToken(from: url)
        #expect(token == nil)
    }

    @Test func returnsNilForSchemeOnly() {
        let url = URL(string: "nippardation:///")!
        let token = DeepLinkRouter.extractShareToken(from: url)
        #expect(token == nil)
    }

    @Test func handlesTokenWithHyphens() {
        let url = URL(string: "nippardation://share/abc-123-def")!
        let token = DeepLinkRouter.extractShareToken(from: url)
        #expect(token == "abc-123-def")
    }

    // MARK: - handleURL (requires MainActor)

    @MainActor
    @Test func handleURLSetsPendingToken() async {
        let router = DeepLinkRouter.shared
        router.clearPendingToken()

        let url = URL(string: "nippardation://share/test123")!
        let handled = router.handleURL(url)

        #expect(handled == true)
        #expect(router.pendingShareToken == "test123")

        // Cleanup
        router.clearPendingToken()
    }

    @MainActor
    @Test func handleURLReturnsFalseForInvalidURL() async {
        let router = DeepLinkRouter.shared
        router.clearPendingToken()

        let url = URL(string: "https://example.com/share/test")!
        let handled = router.handleURL(url)

        #expect(handled == false)
        #expect(router.pendingShareToken == nil)
    }

    @MainActor
    @Test func clearPendingTokenResetsState() async {
        let router = DeepLinkRouter.shared

        let url = URL(string: "nippardation://share/clear_test")!
        _ = router.handleURL(url)
        #expect(router.pendingShareToken != nil)

        router.clearPendingToken()
        #expect(router.pendingShareToken == nil)
    }
}
