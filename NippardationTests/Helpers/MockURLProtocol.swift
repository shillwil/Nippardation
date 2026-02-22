//
//  MockURLProtocol.swift
//  NippardationTests
//
//  Mock URL protocol for intercepting network requests in tests
//

import Foundation

/// Mock URL protocol for testing network requests
final class MockURLProtocol: URLProtocol {

    typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data?)

    private static let sessionIDHeader = "X-MockURLProtocol-Session-ID"
    private static let stateQueue = DispatchQueue(label: "MockURLProtocol.State")

    // Global (legacy) state
    private static var globalRequestHandler: RequestHandler?
    private static var globalRecordedRequests: [URLRequest] = []

    // Session-scoped state for parallel-safe tests
    private static var sessionRequestHandlers: [String: RequestHandler] = [:]
    private static var sessionRecordedRequests: [String: [URLRequest]] = [:]

    /// Legacy shared handler. Prefer `setRequestHandler(for:_:)` to avoid cross-test interference.
    static var requestHandler: RequestHandler? {
        get { stateQueue.sync { globalRequestHandler } }
        set { stateQueue.sync { globalRequestHandler = newValue } }
    }

    /// Legacy shared request capture. Prefer `recordedRequests(for:)` for session-scoped access.
    static var recordedRequests: [URLRequest] {
        get { stateQueue.sync { globalRecordedRequests } }
        set { stateQueue.sync { globalRecordedRequests = newValue } }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        let sessionID = request.value(forHTTPHeaderField: Self.sessionIDHeader)
        Self.recordRequest(request, for: sessionID)

        guard let handler = Self.handler(for: sessionID) ?? Self.requestHandler else {
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
    static func reset(sessionID: String? = nil) {
        stateQueue.sync {
            if let sessionID {
                sessionRequestHandlers[sessionID] = nil
                sessionRecordedRequests[sessionID] = nil
                return
            }

            globalRequestHandler = nil
            globalRecordedRequests = []
            sessionRequestHandlers = [:]
            sessionRecordedRequests = [:]
        }
    }

    /// Generates a unique session ID for isolating handlers between tests.
    static func makeSessionID() -> String {
        UUID().uuidString
    }

    /// Set a handler scoped to a specific mock URLSession.
    static func setRequestHandler(for sessionID: String, _ handler: @escaping RequestHandler) {
        stateQueue.sync {
            sessionRequestHandlers[sessionID] = handler
        }
    }

    /// Get requests recorded for a specific mock URLSession.
    static func recordedRequests(for sessionID: String) -> [URLRequest] {
        stateQueue.sync {
            sessionRecordedRequests[sessionID] ?? []
        }
    }

    /// Create a mock URLSession configured to use this protocol
    static func mockSession(sessionID: String = UUID().uuidString) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        var headers = config.httpAdditionalHeaders ?? [:]
        headers[sessionIDHeader] = sessionID
        config.httpAdditionalHeaders = headers
        return URLSession(configuration: config)
    }

    private static func handler(for sessionID: String?) -> RequestHandler? {
        guard let sessionID else { return nil }
        return stateQueue.sync { sessionRequestHandlers[sessionID] }
    }

    private static func recordRequest(_ request: URLRequest, for sessionID: String?) {
        stateQueue.sync {
            if let sessionID {
                sessionRecordedRequests[sessionID, default: []].append(request)
            } else {
                globalRecordedRequests.append(request)
            }
        }
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
