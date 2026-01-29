//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import SwiftUI
import VLCUI

// MARK: - Background Audio Player

/// Persistent audio player that lives at the app level (in MainTabView).
/// This allows music playback to continue when navigating away from MusicPlayer.
/// Hidden from view but keeps VLC audio session alive.
struct BackgroundAudioPlayer: View {

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    @StateObject
    private var audioState = BackgroundAudioState()

    var body: some View {
        // Only render the VLC player when we have an active audio item
        if manager.isAudioPlaybackActive {
            BackgroundVLCPlayer()
                .environmentObject(manager)
                .environmentObject(audioState)
                .frame(width: 1, height: 1)
                .opacity(0)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Background Audio State

/// Shared state for background audio playback
@MainActor
final class BackgroundAudioState: ObservableObject {

    @Published
    var proxy: VLCMediaPlayerProxy = .init()

    /// Whether the VLC player has been initialized for current item
    @Published
    var isPlayerReady: Bool = false
}

// MARK: - Background VLC Player

/// The actual VLC player view for audio playback
private struct BackgroundVLCPlayer: View {

    @EnvironmentObject
    private var manager: MediaPlayerManager

    @EnvironmentObject
    private var audioState: BackgroundAudioState

    /// State debouncing to prevent race conditions from rapid state changes
    @State
    private var stateDebounceTask: Task<Void, Never>?

    /// Last reported VLC state to filter duplicates
    @State
    private var lastReportedState: VLCVideoPlayer.State?

    private func vlcConfiguration(for item: MediaPlayerItem) -> VLCVideoPlayer.Configuration {
        var configuration = VLCVideoPlayer.Configuration(url: item.url)
        configuration.autoPlay = true
        configuration.startSeconds = item.baseItem.startSeconds ?? .zero

        // Audio-specific options for smooth playback
        var options: [String: Any] = [
            "network-caching": 3000,
            "file-caching": 3000,
        ]

        configuration.options = options
        return configuration
    }

    var body: some View {
        if let playbackItem = manager.playbackItem,
           manager.state != .stopped,
           manager.item.type == .audio
        {
            VLCVideoPlayer(configuration: vlcConfiguration(for: playbackItem))
                .proxy(audioState.proxy.vlcUIProxy)
                .onSecondsUpdated { newSeconds, _ in
                    Task { @MainActor in
                        manager.seconds = newSeconds
                    }
                }
                .onStateUpdated { state, _ in
                    handleStateUpdate(state)
                }
                .onAppear {
                    // Connect proxy to manager when player appears
                    manager.proxy = audioState.proxy
                    audioState.isPlayerReady = true
                }
                .onReceive(manager.$playbackItem) { playbackItem in
                    guard let playbackItem, playbackItem.baseItem.type == .audio else { return }
                    audioState.proxy.vlcUIProxy.playNewMedia(vlcConfiguration(for: playbackItem))
                }
        }
    }

    private func handleStateUpdate(_ state: VLCVideoPlayer.State) {
        // Cancel any pending debounce task
        stateDebounceTask?.cancel()

        // Skip duplicate states to prevent race conditions
        guard state != lastReportedState else { return }

        // Handle buffering states immediately (no debounce needed)
        switch state {
        case .buffering, .esAdded, .opening:
            audioState.proxy.isBuffering.value = true
            lastReportedState = state
            return
        default:
            break
        }

        // Debounce play/pause states to handle rapid transitions
        stateDebounceTask = Task { @MainActor in
            // Small delay to debounce rapid state changes
            try? await Task.sleep(for: .milliseconds(100))

            guard !Task.isCancelled else { return }

            // Update last reported state
            lastReportedState = state

            switch state {
            case .buffering, .esAdded, .opening:
                // Already handled above
                break
            case .ended:
                audioState.proxy.isBuffering.value = false
                await manager.ended()
            case .stopped:
                break
            case .error:
                audioState.proxy.isBuffering.value = false
                await manager.error(ErrorMessage("Unable to play audio"))
            case .playing:
                audioState.proxy.isBuffering.value = false
                await manager.setPlaybackRequestStatus(status: .playing)
            case .paused:
                await manager.setPlaybackRequestStatus(status: .paused)
            }
        }
    }
}
