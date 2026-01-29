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

                // Album art (centered, sharp, scaled to accommodate controls)
                AlbumArtView()
                    .frame(width: 500, height: 500)
                    .shadow(color: .black.opacity(0.6), radius: 40)
                    .scaleEffect(0.9)

                Spacer()
                    .frame(height: 40)

                // Track info (offset to accommodate controls)
                TrackInfoView()
                    .offset(y: -20)

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
    var shouldDismiss: Bool = false
}
