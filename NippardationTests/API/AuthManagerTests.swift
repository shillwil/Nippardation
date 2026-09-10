//
//  AuthManagerTests.swift
//  NippardationTests
//
//  The backend-login failure path: a non-2xx used to reach the user as
//  "The operation couldn't be completed. (Backend login failed error 429.)"
//

import Testing
import Foundation
@testable import Nippardation

@Suite("AuthManager backend errors")
struct AuthManagerTests {

    private func data(_ json: String) -> Data { Data(json.utf8) }

    @Test func prefersTheBackendsOwnMessage() {
        let body = data(#"{"success":false,"message":"Too many requests, please try again later."}"#)
        #expect(AuthManager.backendMessage(from: body, statusCode: 429) == "Too many requests, please try again later.")
    }

    @Test func fallsBackToTheErrorField() {
        let body = data(#"{"success":false,"error":"Invalid or expired token"}"#)
        #expect(AuthManager.backendMessage(from: body, statusCode: 401) == "Invalid or expired token")
    }

    @Test func explainsRateLimitingWhenTheBodyIsUnhelpful() {
        let message = AuthManager.backendMessage(from: data("not json"), statusCode: 429)
        #expect(message.contains("Too many sign-in attempts"))
        #expect(message.contains("429") == false)
    }

    @Test func explainsAnUnverifiedSession() {
        let message = AuthManager.backendMessage(from: Data(), statusCode: 401)
        #expect(message.contains("couldn't be verified"))
    }

    @Test func explainsAServerFault() {
        let message = AuthManager.backendMessage(from: Data(), statusCode: 503)
        #expect(message.contains("server is having trouble"))
    }

    @Test func namesTheStatusCodeOnlyAsALastResort() {
        let message = AuthManager.backendMessage(from: Data(), statusCode: 418)
        #expect(message.contains("418"))
    }

    @Test func anEmptyMessageFieldDoesNotWinOverTheFallback() {
        let message = AuthManager.backendMessage(from: data(#"{"message":""}"#), statusCode: 429)
        #expect(message.contains("Too many sign-in attempts"))
    }
}
