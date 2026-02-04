//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Foundation
import Logging

/// Centralized service for managing AVAudioSession lifecycle.
///
/// This service ensures the audio session is properly configured BEFORE
/// any media player (VLC or AVKit) attempts playback. This prevents
/// race conditions where the player starts before the audio session
/// is active, resulting in silent playback.
///
/// - Important: Configure the audio session via this service in
///   `MediaPlayerManager.init()` before any player views render.
@MainActor
final class AudioSessionService {

    static let shared = AudioSessionService()

    private let logger = Logger(label: "AudioSessionService")

    /// Whether the audio session is currently active for playback
    private(set) var isSessionActive: Bool = false

    private init() {}

    // MARK: - Public API

    /// Configures and activates the audio session for media playback.
    ///
    /// This should be called:
    /// - In `MediaPlayerManager.init()` before any views render
    /// - Before starting any media playback
    ///
    /// The `.playback` category is used to:
    /// - Allow audio to play when the device is locked or silent
    /// - Support background audio (when combined with UIBackgroundModes)
    /// - Take priority over other audio apps
    ///
    /// - Throws: An error if the audio session cannot be configured or activated.
    func configureForPlayback() throws {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            // Set category before activating - Apple best practice
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            isSessionActive = true
            logger.trace("Audio session configured and activated for playback")
        } catch {
            isSessionActive = false
            logger.critical("Failed to configure audio session: \(error.localizedDescription)")
            throw error
        }
    }

    /// Deactivates the audio session when playback stops.
    ///
    /// This notifies other apps that they can resume their audio.
    ///
    /// - Throws: An error if the audio session cannot be deactivated.
    func deactivateSession() throws {
        guard isSessionActive else {
            logger.trace("Audio session already inactive, skipping deactivation")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isSessionActive = false
            logger.trace("Audio session deactivated")
        } catch {
            logger.error("Failed to deactivate audio session: \(error.localizedDescription)")
            throw error
        }
    }

    /// Ensures the audio session is active, configuring it if necessary.
    ///
    /// This is a safety method for cases where playback might start
    /// before the session was properly configured (e.g., edge cases).
    ///
    /// - Returns: `true` if the session is now active, `false` if configuration failed.
    @discardableResult
    func ensureSessionActive() -> Bool {
        if isSessionActive {
            return true
        }

        do {
            try configureForPlayback()
            return true
        } catch {
            logger.error("Failed to ensure audio session active: \(error.localizedDescription)")
            return false
        }
    }
}
