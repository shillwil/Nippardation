//
//  PasteLinkSheetTests.swift
//  NippardationTests
//
//  What the Paste a link sheet takes from the system Paste button's item providers.
//

import Testing
import Foundation
import UniformTypeIdentifiers
@testable import Nippardation

@Suite("Paste a link")
@MainActor
struct PasteLinkSheetTests {

    private let link = "https://recess.fit/p/abc123"

    // MARK: - Item providers

    @Test func readsALinkCopiedAsAURL() async {
        // A share sheet's Copy puts the link on the clipboard as a URL item, with no text.
        let provider = NSItemProvider(object: URL(string: link)! as NSURL)

        let text = await PasteLinkSheet.linkText(from: [provider])

        #expect(text == link)
        #expect(PasteLinkSheet.shareURL(from: text ?? "")?.absoluteString == link)
    }

    @Test func readsALinkCopiedAsText() async {
        let provider = NSItemProvider(object: "recess.fit/p/abc123" as NSString)

        let text = await PasteLinkSheet.linkText(from: [provider])

        #expect(text == "recess.fit/p/abc123")
        #expect(PasteLinkSheet.shareURL(from: text ?? "")?.absoluteString == link)
    }

    @Test func skipsItemsWithNoTextOrURL() async {
        let image = NSItemProvider(item: Data([0x89, 0x50, 0x4E, 0x47]) as NSData, typeIdentifier: UTType.png.identifier)
        let textItem = NSItemProvider(object: link as NSString)

        #expect(await PasteLinkSheet.linkText(from: [image]) == nil)
        #expect(await PasteLinkSheet.linkText(from: [image, textItem]) == link)
    }

    @Test func nothingPastedReadsAsNoText() async {
        #expect(await PasteLinkSheet.linkText(from: []) == nil)
    }

    // MARK: - Link parsing

    @Test func acceptsEverySupportedLinkForm() {
        #expect(PasteLinkSheet.shareURL(from: link) != nil)
        #expect(PasteLinkSheet.shareURL(from: "  recess://plan/abc123\n") != nil)
        #expect(PasteLinkSheet.shareURL(from: "nippardation://share/abc123") != nil)
        #expect(PasteLinkSheet.shareURL(from: "recess.fit/p/abc123")?.absoluteString == link)
    }

    @Test func rejectsTextThatIsNotAPlanLink() {
        #expect(PasteLinkSheet.shareURL(from: "") == nil)
        #expect(PasteLinkSheet.shareURL(from: "https://example.com/p/abc123") == nil)
        #expect(PasteLinkSheet.shareURL(from: "Check out my plan") == nil)
    }
}
