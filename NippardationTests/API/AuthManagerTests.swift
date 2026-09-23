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

@Suite("AuthManager Firebase error copy")
struct AuthManagerFirebaseErrorTests {

    /// Firebase reports its auth failures as NSErrors in this domain, with the
    /// `AuthErrorCode` raw value as the code.
    private func firebaseError(_ code: Int, description: String = "Firebase's own wording.") -> Error {
        NSError(
            domain: "FIRAuthErrorDomain",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }

    @Test func aStraySpaceDoesNotReadAsAWrongEmailAddress() {
        // 17008 = invalidEmail, which is what a trailing space from autofill comes back as.
        let message = AuthManager.authMessage(for: firebaseError(17008))
        #expect(message.contains("stray space"))
        #expect(message.contains("badly formatted") == false)
    }

    @Test func anAddressAlreadyTakenPointsAtSigningIn() {
        let message = AuthManager.authMessage(for: firebaseError(17007))
        #expect(message.contains("already has an account"))
        #expect(message.contains("Sign in"))
    }

    @Test func anAddressAlreadyTakenIsRecognisedSoTheFormCanFlip() {
        #expect(AuthManager.isEmailAlreadyInUse(firebaseError(17007)))
        #expect(AuthManager.isEmailAlreadyInUse(firebaseError(17008)) == false)
    }

    @Test func aWrongPasswordSaysSoRatherThanNamingACredential() {
        // 17004 = invalidCredential, which is what a wrong password became once email
        // enumeration protection was switched on.
        let message = AuthManager.authMessage(for: firebaseError(17004))
        #expect(message.contains("don't match an account"))
        #expect(message.lowercased().contains("malformed") == false)
    }

    @Test func aShortPasswordSaysHowShort() {
        #expect(AuthManager.authMessage(for: firebaseError(17026)).contains("6 characters"))
    }

    @Test func aNetworkFailureIsWorthRetrying() {
        #expect(AuthManager.authMessage(for: firebaseError(17020)).contains("connection"))
    }

    @Test func aFirebaseFailureWeDoNotRewriteKeepsFirebasesOwnWording() {
        // 17999 = internalError: a real Firebase code, deliberately not in the switch.
        // Falling through to Firebase's text keeps an unusual failure diagnosable from a
        // screenshot instead of flattening it into a generic apology.
        let message = AuthManager.authMessage(for: firebaseError(17999, description: "Something new."))
        #expect(message == "Something new.")
    }

    @Test func aNonFirebaseErrorKeepsItsOwnWording() {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: -1009,
            userInfo: [NSLocalizedDescriptionKey: "Offline."]
        )
        #expect(AuthManager.authMessage(for: error) == "Offline.")
    }

    @Test func theDiagnosticCarriesFirebasesOwnNameForTheFailure() {
        // Firebase attaches this on every error it raises (AuthErrorUtils.swift).
        let error = NSError(
            domain: "FIRAuthErrorDomain",
            code: 17007,
            userInfo: [
                NSLocalizedDescriptionKey: "The email address is already in use by another account.",
                "FIRAuthErrorUserInfoNameKey": "ERROR_EMAIL_ALREADY_IN_USE",
            ]
        )
        let diagnostic = AuthManager.diagnostic(for: error)
        #expect(diagnostic.contains("ERROR_EMAIL_ALREADY_IN_USE"))
        #expect(diagnostic.contains("17007"))
    }

    @Test func theDiagnosticStillNamesTheCodeWithoutFirebasesLabel() {
        let diagnostic = AuthManager.diagnostic(for: firebaseError(17020))
        #expect(diagnostic.contains("17020"))
        #expect(diagnostic.contains("FIRAuthErrorDomain"))
    }

    @Test func theDiagnosticLeaksNoCredentials() {
        let error = NSError(
            domain: "FIRAuthErrorDomain",
            code: 17009,
            userInfo: [
                NSLocalizedDescriptionKey: "The password is invalid for brother@example.com.",
                "FIRAuthErrorUserInfoNameKey": "ERROR_WRONG_PASSWORD",
            ]
        )
        let diagnostic = AuthManager.diagnostic(for: error)
        #expect(diagnostic.contains("@example.com") == false)
        #expect(diagnostic.contains("ERROR_WRONG_PASSWORD"))
    }
}
