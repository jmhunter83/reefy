//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI
import VLCUI

struct MusicPlayer: View {

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    @LazyState
    private var proxy: VLCMediaPlayerProxy

    @Router
    private var router

    @State
    private var isBeingDismissedByTransition = false

    @StateObject
    private var containerState: MusicPlayerContainerState = .init()

    init() {
        self._proxy = .init(wrappedValue: VLCMediaPlayerProxy())
    }

    var body: some View {
        ZStack {
            // Background: Blurred album art
            AlbumArtBackground()

            // Main content
            VStack(spacing: 0) {
                Spacer()

                // Album art (centered, sharp)
                AlbumArtView()
                    .frame(width: 400, height: 400)
                    .shadow(color: .black.opacity(0.5), radius: 30)

                Spacer()
                    .frame(height: 60)

                // Track info
                TrackInfoView()

                Spacer()
                    .frame(height: 40)

                // Transport controls
                MusicPlayerControls()
                    .padding(.horizontal, 100)
                    .padding(.bottom, 80)
            }

            // Hidden VLC player (audio only - no video rendering)
            VLCAudioPlayer(proxy: proxy)
                .frame(width: 1, height: 1)
                .opacity(0)
        }
        .environmentObject(manager)
        .environmentObject(containerState)
        .onAppear {
            manager.proxy = proxy
            manager.start()
        }
        .onDisappear {
            proxy.stop()
            manager.stop()
        }
        .onReceive(manager.$state) { newState in
            if newState == .stopped, !isBeingDismissedByTransition {
                router.dismiss()
            }
        }
        .onReceive(containerState.$shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                proxy.stop()
                router.dismiss()
            }
        }
        .alert(
            L10n.error,
            isPresented: .constant(manager.error != nil)
        ) {
            Button(L10n.close, role: .cancel) {
                Container.shared.mediaPlayerManager.reset()
                router.dismiss()
            }
        } message: {
            Text("Unable to load this item.")
        }
    }
}

// MARK: - VLC Audio Player (Hidden)

/// Minimal VLC player view that handles audio playback without video rendering
private struct VLCAudioPlayer: View {

    @EnvironmentObject
    private var manager: MediaPlayerManager

    let proxy: VLCMediaPlayerProxy

    private func vlcConfiguration(for item: MediaPlayerItem) -> VLCVideoPlayer.Configuration {
        var configuration = VLCVideoPlayer.Configuration(url: item.url)
        configuration.autoPlay = true
        configuration.startSeconds = item.baseItem.startSeconds ?? .zero

        // Audio-specific options
        var options: [String: Any] = [
            "network-caching": 3000,
            "file-caching": 3000,
        ]

        configuration.options = options
        return configuration
    }

    var body: some View {
        if let playbackItem = manager.playbackItem, manager.state != .stopped {
            VLCVideoPlayer(configuration: vlcConfiguration(for: playbackItem))
                .proxy(proxy.vlcUIProxy)
                .onSecondsUpdated { newSeconds, _ in
                    Task { @MainActor in
                        manager.seconds = newSeconds
                    }
                }
                .onStateUpdated { state, _ in
                    Task { @MainActor in
                        switch state {
                        case .buffering, .esAdded, .opening:
                            proxy.isBuffering.value = true
                        case .ended:
                            proxy.isBuffering.value = false
                            await manager.ended()
                        case .stopped:
                            break
                        case .error:
                            proxy.isBuffering.value = false
                            await manager.error(ErrorMessage("Unable to play audio"))
                        case .playing:
                            proxy.isBuffering.value = false
                            await manager.setPlaybackRequestStatus(status: .playing)
                        case .paused:
                            await manager.setPlaybackRequestStatus(status: .paused)
                        }
                    }
                }
                .onReceive(manager.$playbackItem) { playbackItem in
                    guard let playbackItem else { return }
                    proxy.vlcUIProxy.playNewMedia(vlcConfiguration(for: playbackItem))
                }
        }
    }
}

// MARK: - Container State

@MainActor
final class MusicPlayerContainerState: ObservableObject {

    @Published
    var isPresentingControls: Bool = true

    @Published
    var shouldDismiss: Bool = false

    /// Timer for auto-hiding controls
    lazy var timer: Debouncer = {
        let timer = Debouncer(duration: 5)
        timer.callback = { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                self.isPresentingControls = false
            }
        }
        return timer
    }()

    init() {
        timer.poke()
    }

    func showControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresentingControls = true
        }
        timer.poke()
    }
}
