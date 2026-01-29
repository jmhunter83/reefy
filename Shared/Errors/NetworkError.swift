//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Errors that can occur during network operations
enum NetworkError: LocalizedError, Hashable {

    // MARK: - URL Errors

    /// The request timed out
    case timeout

    /// Unable to find the host
    case hostNotFound

    /// Cannot connect to the host
    case cannotConnect

    /// The network connection was lost
    case connectionLost

    /// No network connection available
    case noConnection

    /// SSL/TLS certificate error
    case sslError

    // MARK: - HTTP Errors

    /// Bad request (400)
    case badRequest(message: String?)

    /// Unauthorized (401) - invalid or missing credentials
    case unauthorized

    /// Forbidden (403) - valid credentials but insufficient permissions
    case forbidden

    /// Resource not found (404)
    case notFound

    /// Server error (5xx)
    case serverError(statusCode: Int, message: String?)

    // MARK: - Other Errors

    /// An unknown error occurred
    case unknown(message: String)

    // MARK: - Initialization from Errors

    /// Create a NetworkError from any Error, attempting to classify it
    static func from(_ error: Error) -> NetworkError {
        // Handle URLError directly
        if let urlError = error as? URLError {
            return from(urlErrorCode: urlError.code.rawValue)
        }

        // Check for nested URLError in underlying error
        if let nsError = error as NSError?,
           nsError.domain == NSURLErrorDomain
        {
            return from(urlErrorCode: nsError.code)
        }

        // Default to unknown with the error description
        return .unknown(message: error.localizedDescription)
    }

    /// Create a NetworkError from a URLError code
    static func from(urlErrorCode: Int) -> NetworkError {
        switch urlErrorCode {
        case -1001:
            return .timeout
        case -1003:
            return .hostNotFound
        case -1004:
            return .cannotConnect
        case -1005:
            return .connectionLost
        case -1009:
            return .noConnection
        case -1200, -1201, -1202, -1203, -1204, -1205, -1206:
            return .sslError
        default:
            return .unknown(message: "URL error with code: \(urlErrorCode)")
        }
    }

    /// Create a NetworkError from an HTTP status code
    static func from(httpStatusCode: Int, message: String? = nil) -> NetworkError {
        switch httpStatusCode {
        case 400:
            return .badRequest(message: message)
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 500 ... 599:
            return .serverError(statusCode: httpStatusCode, message: message)
        default:
            return .unknown(message: message ?? "HTTP error with status: \(httpStatusCode)")
        }
    }

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .timeout:
            return L10n.networkTimedOut
        case .hostNotFound:
            return L10n.unableToFindHost
        case .cannotConnect:
            return L10n.cannotConnectToHost
        case .connectionLost:
            return L10n.error // TODO: Add specific localization
        case .noConnection:
            return L10n.error // TODO: Add specific localization
        case .sslError:
            return L10n.error // TODO: Add specific localization
        case let .badRequest(message):
            return message ?? L10n.error
        case .unauthorized:
            return L10n.unauthorizedUser
        case .forbidden:
            return L10n.error // TODO: Add specific localization
        case .notFound:
            return L10n.error // TODO: Add specific localization
        case let .serverError(_, message):
            return message ?? L10n.error
        case let .unknown(message):
            return message
        }
    }

    /// A user-friendly title for the error
    var errorTitle: String {
        switch self {
        case .unauthorized:
            return L10n.unauthorized
        default:
            return L10n.error
        }
    }

    /// Whether this error is recoverable (user can retry)
    var isRecoverable: Bool {
        switch self {
        case .timeout, .connectionLost, .noConnection, .cannotConnect:
            return true
        case .hostNotFound, .sslError, .unauthorized, .forbidden, .notFound:
            return false
        case .badRequest, .serverError, .unknown:
            return false
        }
    }
}
