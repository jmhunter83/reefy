//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI

// TODO: respond properly to end of playback
//       - when item changes
// TODO: only send stop on manager stop, not per-item

class MediaProgressObserver: ViewModel, MediaPlayerObserver {

    weak var manager: MediaPlayerManager? {
        didSet {
            if let manager {
                setup(with: manager)
            }
        }
    }

    private let timer = PokeIntervalTimer()
    private var hasSentStart = false
    private var hasMarkedAsPlayed = false
    private weak var item: MediaPlayerItem?
    private var lastPlaybackRequestStatus: MediaPlayerManager.PlaybackRequestStatus = .playing

    init(item: MediaPlayerItem) {
        self.item = item
        super.init()
    }

    private func sendReport() {
        guard let item else { return }

        switch lastPlaybackRequestStatus {
        case .playing:
            if hasSentStart {
                sendProgressReport(for: item, seconds: manager?.seconds)
            } else {
                sendStartReport(for: item, seconds: manager?.seconds)
            }
        case .paused:
            sendProgressReport(for: item, seconds: manager?.seconds, isPaused: true)
        }
    }

    private func setup(with manager: MediaPlayerManager) {
        cancellables = []

        timer.sink { [weak self] in
            self?.sendReport()
            self?.timer.poke()
        }
        .store(in: &cancellables)

        manager.actions
            .sink { [weak self] in self?.didReceive(action: $0) }
            .store(in: &cancellables)

        manager.$playbackItem
            .sink { [weak self] in self?.playbackItemDidChange($0) }
            .store(in: &cancellables)

        manager.$playbackRequestStatus
            .sink { [weak self] in self?.playbackRequestStatusDidChange($0) }
            .store(in: &cancellables)
    }

    private func playbackItemDidChange(_ newItem: MediaPlayerItem?) {
        timer.poke()

        if let item, newItem !== item {
            // Check completion threshold before sending stop report (covers autoplay scenarios)
            checkAndMarkCompleted(for: item, seconds: manager?.seconds)
            sendStopReport(for: item, seconds: manager?.seconds)

            self.item = newItem
            self.hasSentStart = false
            self.hasMarkedAsPlayed = false
            sendReport()
        }
    }

    private func playbackRequestStatusDidChange(_ newStatus: MediaPlayerManager.PlaybackRequestStatus) {
        timer.poke()
        lastPlaybackRequestStatus = newStatus
    }

    // TODO: respond to error
    // TODO: respond properly to ended
    private func didReceive(action: MediaPlayerManager._Action) {
        switch action {
        case .stop:
            cancellables = []
            timer.stop()
            if let item {
                sendStopReport(for: item, seconds: manager?.seconds)
            }
            item = nil
        default: ()
        }
    }

    private func sendStartReport(for item: MediaPlayerItem, seconds: Duration?) {

        #if DEBUG
        guard Defaults[.sendProgressReports] else { return }
        #endif

        Task {
            do {
                var info = PlaybackStartInfo()
                info.audioStreamIndex = item.selectedAudioStreamIndex
                info.itemID = item.baseItem.id
                info.mediaSourceID = item.mediaSource.id
                info.playSessionID = item.playSessionID
                info.positionTicks = seconds?.ticks
                info.sessionID = item.playSessionID
                info.subtitleStreamIndex = item.selectedSubtitleStreamIndex

                let request = Paths.reportPlaybackStart(info)
                _ = try await userSession!.client.send(request)

                self.hasSentStart = true
            } catch {
                logger.error("Failed to send playback start report: \(error.localizedDescription)")
            }
        }
    }

    private func sendStopReport(for item: MediaPlayerItem, seconds: Duration?) {
        // Check completion threshold when stop is triggered (covers manual stop)
        checkAndMarkCompleted(for: item, seconds: seconds)

        #if DEBUG
        guard Defaults[.sendProgressReports] else { return }
        #endif

        Task {
            do {
                var info = PlaybackStopInfo()
                info.itemID = item.baseItem.id
                info.mediaSourceID = item.mediaSource.id
                info.positionTicks = seconds?.ticks
                info.sessionID = item.playSessionID

                let request = Paths.reportPlaybackStopped(info)
                _ = try await userSession!.client.send(request)
            } catch {
                logger.error("Failed to send playback stop report: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Auto-Mark Played

    /// Check if playback has reached the threshold for auto-marking as played
    private func checkAndMarkCompleted(for item: MediaPlayerItem, seconds: Duration?) {
        guard !hasMarkedAsPlayed,
              let seconds,
              let runtime = item.baseItem.runtime,
              runtime > .zero else { return }

        let playedFraction = seconds.seconds / runtime.seconds
        let threshold = Defaults[.VideoPlayer.autoMarkPlayedThreshold]

        if playedFraction >= threshold {
            hasMarkedAsPlayed = true
            markItemAsPlayed(item)
        }
    }

    /// Mark item as played via Jellyfin API
    private func markItemAsPlayed(_ item: MediaPlayerItem) {
        guard let itemID = item.baseItem.id else { return }

        Task {
            do {
                let request = Paths.markPlayedItem(
                    itemID: itemID,
                    userID: userSession!.user.id
                )
                _ = try await userSession!.client.send(request)
                Notifications[.itemShouldRefreshMetadata].post(itemID)
                logger.info("Auto-marked item as played: \(item.baseItem.displayTitle)")
            } catch {
                logger.warning("Failed to auto-mark item as played: \(error.localizedDescription)")
            }
        }
    }

    private func sendProgressReport(for item: MediaPlayerItem, seconds: Duration?, isPaused: Bool = false) {

        #if DEBUG
        guard Defaults[.sendProgressReports] else { return }
        #endif

        Task {
            do {
                var info = PlaybackProgressInfo()
                info.audioStreamIndex = item.selectedAudioStreamIndex
                info.isPaused = isPaused
                info.itemID = item.baseItem.id
                info.mediaSourceID = item.mediaSource.id
                info.playSessionID = item.playSessionID
                info.positionTicks = seconds?.ticks
                info.sessionID = item.playSessionID
                info.subtitleStreamIndex = item.selectedSubtitleStreamIndex

                let request = Paths.reportPlaybackProgress(info)
                _ = try await userSession!.client.send(request)
            } catch {
                // Don't log progress errors at error level - they're frequent and expected during network issues
                logger.warning("Failed to send playback progress report: \(error.localizedDescription)")
            }
        }
    }

    deinit {
        timer.stop()
        cancellables.removeAll()
    }
}
