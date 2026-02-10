//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Errors that can occur during media playback
enum MediaError: LocalizedError, Hashable, SystemImageable {

    // MARK: - Playback Errors

    /// No playable media source available for this item
    case noPlayableSource

    /// The media format is not supported
    case unsupportedFormat(format: String?)

    /// Transcoding failed on the server
    case transcodingFailed(reason: String?)

    /// The media stream ended unexpectedly
    case streamEnded

    /// Failed to load the media
    case loadFailed(reason: String?)

    // MARK: - Item Errors

    /// The requested item was not found
    case itemNotFound(itemId: String?)

    /// The item has no associated media
    case noMediaInfo

    /// The item type is not playable
    case notPlayable

    // MARK: - Session Errors

    /// Failed to create a playback session
    case sessionCreationFailed

    /// The playback session expired
    case sessionExpired

    /// Failed to report playback progress
    case reportingFailed

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .noPlayableSource:
            return L10n.mediaErrorNoPlayableSource
        case let .unsupportedFormat(format):
            if let format {
                return L10n.mediaErrorUnsupportedFormatNamed(format)
            }
            return L10n.mediaErrorUnsupportedFormat
        case let .transcodingFailed(reason):
            return reason ?? L10n.mediaErrorTranscodingFailed
        case .streamEnded:
            return L10n.mediaErrorStreamEnded
        case let .loadFailed(reason):
            return reason ?? L10n.mediaErrorLoadFailed
        case let .itemNotFound(itemId):
            if let itemId {
                return L10n.mediaErrorItemNotFoundNamed(itemId)
            }
            return L10n.mediaErrorItemNotFound
        case .noMediaInfo:
            return L10n.mediaErrorNoMediaInfo
        case .notPlayable:
            return L10n.mediaErrorNotPlayable
        case .sessionCreationFailed:
            return L10n.mediaErrorSessionCreationFailed
        case .sessionExpired:
            return L10n.mediaErrorSessionExpired
        case .reportingFailed:
            return L10n.mediaErrorReportingFailed
        }
    }

    /// A user-friendly title for the error
    var errorTitle: String {
        switch self {
        case .noPlayableSource, .unsupportedFormat, .notPlayable:
            return L10n.mediaErrorTitleCannotPlay
        case .transcodingFailed:
            return L10n.mediaErrorTranscoding
        case .streamEnded, .loadFailed:
            return L10n.mediaErrorPlayback
        case .itemNotFound, .noMediaInfo:
            return L10n.mediaErrorItemError
        case .sessionCreationFailed, .sessionExpired, .reportingFailed:
            return L10n.mediaErrorSessionError
        }
    }

    /// Whether the user should retry
    var isRetryable: Bool {
        switch self {
        case .transcodingFailed, .streamEnded, .loadFailed, .sessionExpired, .reportingFailed:
            return true
        case .noPlayableSource, .unsupportedFormat, .itemNotFound, .noMediaInfo, .notPlayable, .sessionCreationFailed:
            return false
        }
    }

    // MARK: - SystemImageable

    var systemImage: String {
        switch self {
        case .noPlayableSource:
            "xmark.circle"
        case .unsupportedFormat:
            "film.fill"
        case .transcodingFailed:
            "gearshape.fill"
        case .streamEnded:
            "exclamationmark.triangle"
        case .loadFailed:
            "exclamationmark.triangle"
        case .itemNotFound:
            "questionmark.circle"
        case .noMediaInfo:
            "info.circle"
        case .notPlayable:
            "xmark.circle"
        case .sessionCreationFailed:
            "server.rack"
        case .sessionExpired:
            "clock.badge.exclamationmark"
        case .reportingFailed:
            "exclamationmark.arrow.circlepath"
        }
    }

    /// A recovery suggestion for the error
    var recoverySuggestion: String? {
        switch self {
        case .noPlayableSource:
            return L10n.mediaErrorRecoveryMovedOrDeleted
        case .unsupportedFormat:
            return L10n.mediaErrorRecoveryDifferentFormat
        case .transcodingFailed:
            return L10n.mediaErrorRecoveryLowerQuality
        case .streamEnded, .loadFailed:
            return L10n.mediaErrorRecoveryTryAgain
        case .itemNotFound:
            return L10n.mediaErrorRecoveryRemovedFromServer
        case .noMediaInfo:
            return L10n.mediaErrorRecoveryRefreshMetadata
        case .notPlayable:
            return nil
        case .sessionCreationFailed:
            return L10n.mediaErrorRecoveryTryAgainOrRestart
        case .sessionExpired:
            return L10n.mediaErrorRecoverySignInAgain
        case .reportingFailed:
            return L10n.mediaErrorRecoveryProgressNotSaved
        }
    }
}
