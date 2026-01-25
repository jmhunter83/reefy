//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Errors specific to YouTube Music API operations
public enum YTMusicError: LocalizedError, Hashable {

    // MARK: - Authentication Errors

    /// OAuth device flow was cancelled by user
    case authCancelled

    /// OAuth device code has expired
    case authCodeExpired

    /// OAuth token refresh failed
    case authTokenRefreshFailed

    /// No valid auth token available
    case notAuthenticated

    /// OAuth authorization was denied by user
    case authDenied

    // MARK: - API Errors

    /// Invalid response format from YouTube Music
    case invalidResponse

    /// Rate limited by YouTube Music API
    case rateLimited

    /// Resource not found (artist, album, playlist, etc.)
    case notFound(resourceType: String)

    /// Request failed with HTTP error
    case httpError(statusCode: Int, message: String?)

    // MARK: - Parsing Errors

    /// Failed to parse response JSON
    case parsingFailed(context: String)

    /// Expected data was missing from response
    case missingData(field: String)

    // MARK: - Network Errors

    /// Network request timed out
    case timeout

    /// No network connection
    case noConnection

    /// Unknown error with message
    case unknown(message: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .authCancelled:
            return "Authentication was cancelled"
        case .authCodeExpired:
            return "Authentication code expired. Please try again."
        case .authTokenRefreshFailed:
            return "Failed to refresh authentication. Please sign in again."
        case .notAuthenticated:
            return "Not signed in to YouTube Music"
        case .authDenied:
            return "Access to YouTube Music was denied"
        case .invalidResponse:
            return "Invalid response from YouTube Music"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case let .notFound(resourceType):
            return "\(resourceType) not found"
        case let .httpError(statusCode, message):
            return message ?? "HTTP error \(statusCode)"
        case let .parsingFailed(context):
            return "Failed to parse response: \(context)"
        case let .missingData(field):
            return "Missing required data: \(field)"
        case .timeout:
            return "Request timed out"
        case .noConnection:
            return "No network connection"
        case let .unknown(message):
            return message
        }
    }

    /// Whether this error is recoverable (user can retry)
    public var isRecoverable: Bool {
        switch self {
        case .timeout, .noConnection, .rateLimited:
            return true
        case .authCodeExpired, .authCancelled, .authDenied, .authTokenRefreshFailed,
             .notAuthenticated, .invalidResponse, .notFound, .httpError,
             .parsingFailed, .missingData, .unknown:
            return false
        }
    }

    /// Whether this error requires re-authentication
    public var requiresReauth: Bool {
        switch self {
        case .authTokenRefreshFailed, .notAuthenticated, .authDenied:
            return true
        default:
            return false
        }
    }
}
