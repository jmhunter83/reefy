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

struct MusicPlayer: View {

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    @Router
    private var router

    @StateObject
    private var containerState: MusicPlayerContainerState = .init()

    var body: some View {
        ZStack {
            // Background: Blurred album art
            AlbumArtBackground()

            // Main content: Album art + track info centered vertically
            VStack(spacing: 0) {
                Spacer()

                // Album art (centered, sharp)
                AlbumArtView()
                    .frame(width: 500, height: 500)
                    .shadow(color: .black.opacity(0.6), radius: 40)
                    .scaleEffect(containerState.isPresentingControls ? 0.9 : 1.0)
                    .animation(.spring(duration: 0.4), value: containerState.isPresentingControls)

                Spacer()
                    .frame(height: 40)

                // Track info
                TrackInfoView()
                    .offset(y: containerState.isPresentingControls ? -20 : 0)
                    .animation(.spring(duration: 0.4), value: containerState.isPresentingControls)

                Spacer()
            }

            // Transport controls floating at bottom (overlay)
            VStack {
                Spacer()

                MusicPlayerControls()
                    .padding(.horizontal, 100)
                    .padding(.bottom, 80)
            }

            // Note: VLC audio player now lives in BackgroundAudioPlayer (MainTabView)
            // This allows music to continue playing when navigating away
        }
        .environmentObject(manager)
        .environmentObject(containerState)
        .onAppear {
            // Start playback if not already playing
            if manager.state == .loadingItem || manager.state == .initial {
                manager.start()
            }
        }
        // Note: No onDisappear stop - audio continues in background via BackgroundAudioPlayer
        .onReceive(manager.$state) { newState in
            // Only auto-dismiss on error, not on stopped (user may have stopped intentionally)
            if newState == .error {
                router.dismiss()
            }
        }
        .onReceive(containerState.$shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                // User explicitly requested stop - stop playback and dismiss
                manager.stop()
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

// MARK: - Container State

@MainActor
final class MusicPlayerContainerState: ObservableObject {

    @Published
    var isPresentingControls: Bool = true

    @Published
    var shouldDismiss: Bool = false

    /// Timer for auto-hiding controls
    let timer: PokeIntervalTimer = .init(defaultInterval: 5)

    private var timerCancellable: AnyCancellable?

    init() {
        timerCancellable = timer.sink { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                self.isPresentingControls = false
            }
        }
        timer.poke()
    }

    func showControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresentingControls = true
        }
        timer.poke()
    }
}
