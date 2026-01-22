//
//  MockURLProtocol.swift
//  NippardationTests
//
//  Mock URL protocol for intercepting network requests in tests
//

import Foundation

/// Mock URL protocol for testing network requests
final class MockURLProtocol: URLProtocol {

    /// Handler to provide mock responses
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    /// Recorded requests for verification
    static var recordedRequests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        Self.recordedRequests.append(request)

        guard let handler = Self.requestHandler else {
            let error = NSError(domain: "MockURLProtocol", code: -1, userInfo: [NSLocalizedDescriptionKey: "No handler set"])
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // Nothing to do
    }

    /// Reset all mock state
    static func reset() {
        requestHandler = nil
        recordedRequests = []
    }

    /// Create a mock URLSession configured to use this protocol
    static func mockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

// MARK: - Response Helpers

extension MockURLProtocol {

    /// Create a successful JSON response
    static func successResponse<T: Encodable>(
        for url: URL,
        body: T,
        statusCode: Int = 200
    ) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        let data = try? JSONEncoder().encode(body)
        return (response, data)
    }

    /// Create an error response
    static func errorResponse(
        for url: URL,
        statusCode: Int,
        message: String? = nil
    ) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        let data = message?.data(using: .utf8)
        return (response, data)
    }
}
