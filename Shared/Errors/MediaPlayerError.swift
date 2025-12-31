//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Specific error types for media playback
enum MediaPlayerError: LocalizedError, SystemImageable {

    case networkError(underlying: Error?)
    case codecNotSupported(codec: String?)
    case mediaSourceUnavailable
    case transcodeFailed(reason: String?)
    case authenticationRequired
    case serverUnreachable
    case playerCrashed(player: String)
    case unknown(message: String?)

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error"
        case let .codecNotSupported(codec):
            return "Unsupported format\(codec.map { ": \($0)" } ?? "")"
        case .mediaSourceUnavailable:
            return "Media source not available"
        case let .transcodeFailed(reason):
            return "Transcoding failed\(reason.map { ": \($0)" } ?? "")"
        case .authenticationRequired:
            return "Authentication required"
        case .serverUnreachable:
            return "Cannot reach server"
        case let .playerCrashed(player):
            return "\(player) player error"
        case let .unknown(message):
            return message ?? "Unknown playback error"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your network connection and try again"
        case .codecNotSupported:
            return "Try switching to a different player in Settings"
        case .mediaSourceUnavailable:
            return "The media file may have been moved or deleted"
        case .transcodeFailed:
            return "Try a lower quality setting or different player"
        case .authenticationRequired:
            return "Please sign in again"
        case .serverUnreachable:
            return "Verify your server address and try again"
        case .playerCrashed:
            return "Try playing again or switch players"
        case .unknown:
            return "Try again or restart the app"
        }
    }

    var systemImage: String {
        switch self {
        case .networkError: "wifi.exclamationmark"
        case .codecNotSupported: "film.fill"
        case .mediaSourceUnavailable: "xmark.circle"
        case .transcodeFailed: "gearshape.fill"
        case .authenticationRequired: "lock.fill"
        case .serverUnreachable: "server.rack"
        case .playerCrashed: "exclamationmark.triangle"
        case .unknown: "questionmark.circle"
        }
    }

    var secondarySystemImage: String { systemImage }
}
