//
//  NetworkError.swift
//  Nippardation
//
//  Phase 0: Network-level error types
//

import Foundation

/// Low-level network errors for the new API layer
/// These are internal errors that get converted to RepositoryError for the UI
/// Named APINetworkError to avoid conflict with existing NetworkError in NetworkManager.swift
enum APINetworkError: LocalizedError {
    /// No network connection available
    case noConnection

    /// DNS resolution failed
    case dnsLookupFailed

    /// Connection timed out
    case connectionTimeout

    /// Request timed out waiting for response
    case requestTimeout

    /// SSL/TLS certificate error
    case sslError(Error?)

    /// Invalid URL
    case invalidURL(String)

    /// Invalid request (encoding failed, etc.)
    case invalidRequest(String)

    /// Invalid response from server
    case invalidResponse

    /// Server returned non-2xx status
    case httpError(statusCode: Int, data: Data?)

    /// Failed to decode response
    case decodingError(Error)

    /// Failed to encode request
    case encodingError(Error)

    /// Request was cancelled
    case cancelled

    /// Unknown error
    case unknown(Error)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No network connection"
        case .dnsLookupFailed:
            return "Could not resolve server address"
        case .connectionTimeout:
            return "Connection timed out"
        case .requestTimeout:
            return "Request timed out"
        case .sslError:
            return "Secure connection failed"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidRequest(let reason):
            return "Invalid request: \(reason)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, _):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .cancelled:
            return "Request was cancelled"
        case .unknown(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

    // MARK: - Conversion to RepositoryError

    /// Converts this network error to a user-facing repository error
    func toRepositoryError() -> RepositoryError {
        switch self {
        case .noConnection, .dnsLookupFailed:
            return .networkUnavailable
        case .connectionTimeout, .requestTimeout:
            return .timeout
        case .sslError, .invalidURL, .invalidRequest, .invalidResponse, .decodingError, .encodingError:
            return .unknown(self)
        case .httpError(let statusCode, let data):
            return mapHTTPError(statusCode: statusCode, data: data)
        case .cancelled:
            return .unknown(nil)
        case .unknown(let error):
            return .unknown(error)
        }
    }

    /// Maps HTTP status codes to appropriate repository errors
    private func mapHTTPError(statusCode: Int, data: Data?) -> RepositoryError {
        // Try to extract error message from response
        var message: String?
        if let data = data {
            message = try? JSONDecoder().decode(ErrorResponse.self, from: data).message
        }

        switch statusCode {
        case 401:
            return .unauthorized
        case 404:
            return .notFound
        case 422:
            return .validationError(message ?? "Validation failed")
        case 429:
            return .rateLimited(retryAfter: nil)
        default:
            return .serverError(statusCode: statusCode, message: message)
        }
    }
}

// MARK: - Supporting Types

/// Standard error response format from server
private struct ErrorResponse: Codable {
    let message: String?
    let error: String?
    let errors: [String: [String]]?
}

// MARK: - URLError Conversion

extension APINetworkError {
    /// Creates an APINetworkError from a URLError
    static func from(_ urlError: URLError) -> APINetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .dnsLookupFailed
        case .timedOut:
            return .connectionTimeout
        case .secureConnectionFailed, .serverCertificateHasBadDate,
             .serverCertificateUntrusted, .serverCertificateNotYetValid:
            return .sslError(urlError)
        case .badURL, .unsupportedURL:
            return .invalidURL(urlError.failingURL?.absoluteString ?? "unknown")
        case .cancelled:
            return .cancelled
        default:
            return .unknown(urlError)
        }
    }
}
