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

    // MARK: - Void link forms

    @Test func extractsTokenFromRecessPlanURL() {
        let url = URL(string: "recess://plan/abc123")!
        #expect(DeepLinkRouter.extractShareToken(from: url) == "abc123")
    }

    @Test func extractsTokenFromRecessShareURL() {
        let url = URL(string: "recess://share/abc123")!
        #expect(DeepLinkRouter.extractShareToken(from: url) == "abc123")
    }

    @Test func extractsTokenFromUniversalLink() {
        #expect(DeepLinkRouter.extractShareToken(from: URL(string: "https://recess.fit/p/a3Bf9kLm2xQz")!) == "a3Bf9kLm2xQz")
        #expect(DeepLinkRouter.extractShareToken(from: URL(string: "https://www.recess.fit/p/abc")!) == "abc")
        #expect(DeepLinkRouter.extractShareToken(from: URL(string: "HTTPS://RECESS.FIT/p/abc")!) == "abc")
    }

    @Test func rejectsUniversalLinksOnOtherHostsOrPaths() {
        #expect(DeepLinkRouter.extractShareToken(from: URL(string: "https://recess.fit/x/abc")!) == nil)
        #expect(DeepLinkRouter.extractShareToken(from: URL(string: "https://recess.fit/p/")!) == nil)
        #expect(DeepLinkRouter.extractShareToken(from: URL(string: "https://example.com/p/abc")!) == nil)
    }

    @Test func rejectsRecessURLsWithOtherHosts() {
        #expect(DeepLinkRouter.extractShareToken(from: URL(string: "recess://workout/abc")!) == nil)
        #expect(DeepLinkRouter.extractShareToken(from: URL(string: "recess://plan/")!) == nil)
    }

    @Test func isShareLinkAcceptsAllForms() {
        #expect(DeepLinkRouter.isShareLink("nippardation://share/abc"))
        #expect(DeepLinkRouter.isShareLink("  recess://plan/abc \n"))
        #expect(DeepLinkRouter.isShareLink("https://recess.fit/p/abc"))
        #expect(DeepLinkRouter.isShareLink("https://apple.com") == false)
        #expect(DeepLinkRouter.isShareLink("not a url") == false)
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
    @Test func openTokenSetsPendingToken() async {
        let router = DeepLinkRouter.shared
        router.clearPendingToken()
        router.open(token: "saved_plan")
        #expect(router.pendingShareToken == "saved_plan")
        router.clearPendingToken()
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
