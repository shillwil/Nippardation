//
//  RepositoryError.swift
//  Nippardation
//
//  Phase 0: Repository-level error types
//

import Foundation

/// Errors that can occur at the repository layer
/// These are user-facing errors that views can handle appropriately
enum RepositoryError: LocalizedError {
    /// Network is unavailable (airplane mode, no connection)
    case networkUnavailable

    /// Server returned an error
    case serverError(statusCode: Int, message: String?)

    /// User is not authenticated
    case unauthorized

    /// Resource was not found
    case notFound

    /// Request timed out
    case timeout

    /// Data validation failed
    case validationError(String)

    /// Local storage error (Core Data)
    case storageError(Error)

    /// Sync conflict between local and remote
    case syncConflict(localId: String, remoteId: String?)

    /// Rate limited by server
    case rateLimited(retryAfter: TimeInterval?)

    /// Unknown error
    case unknown(Error?)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network settings."
        case .serverError(let statusCode, let message):
            if let message = message {
                return message
            }
            return "Server error (\(statusCode)). Please try again later."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .notFound:
            return "The requested item could not be found."
        case .timeout:
            return "The request timed out. Please try again."
        case .validationError(let message):
            return message
        case .storageError:
            return "Failed to save data locally. Please try again."
        case .syncConflict:
            return "There was a conflict syncing your data. Please refresh and try again."
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Too many requests. Please wait \(Int(seconds)) seconds."
            }
            return "Too many requests. Please try again later."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }

    var failureReason: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable"
        case .serverError(let statusCode, _):
            return "HTTP \(statusCode)"
        case .unauthorized:
            return "Authentication required"
        case .notFound:
            return "Resource not found"
        case .timeout:
            return "Request timeout"
        case .validationError:
            return "Validation failed"
        case .storageError(let error):
            return error.localizedDescription
        case .syncConflict:
            return "Sync conflict"
        case .rateLimited:
            return "Rate limited"
        case .unknown(let error):
            return error?.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Connect to the internet to sync your data."
        case .serverError:
            return "If the problem persists, contact support."
        case .unauthorized:
            return "Sign in to continue."
        case .notFound:
            return "The item may have been deleted."
        case .timeout:
            return "Check your connection and try again."
        case .validationError:
            return "Fix the validation errors and try again."
        case .storageError:
            return "Free up device storage and try again."
        case .syncConflict:
            return "Pull the latest data and re-apply your changes."
        case .rateLimited:
            return "Wait before making more requests."
        case .unknown:
            return "Try again or contact support."
        }
    }

    // MARK: - Convenience

    /// Whether this error indicates the user should retry
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .rateLimited:
            return true
        case .serverError(let code, _):
            return code >= 500
        default:
            return false
        }
    }

    /// Whether this error requires user authentication
    var requiresAuthentication: Bool {
        if case .unauthorized = self {
            return true
        }
        return false
    }
}
