//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import NukeUI
import SwiftUI

// MARK: - Now Playing Mini Bar

/// Spotify-style floating mini-player that appears when music is playing in the background.
/// Positioned at the bottom of the screen, above the tab bar.
struct NowPlayingMiniBar: View {

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    @Router
    private var router

    @FocusState
    private var isFocused: Bool

    @State
    private var isPressed: Bool = false

    /// Whether to show the mini bar
    private var isVisible: Bool {
        manager.isAudioPlaybackActive
    }

    /// Current track title
    private var trackTitle: String {
        manager.item.displayTitle
    }

    /// Artist name
    private var artistName: String? {
        manager.item.artists?.first ?? manager.item.albumArtist
    }

    /// Whether playback is active
    private var isPlaying: Bool {
        manager.playbackRequestStatus == .playing
    }

    /// Progress percentage (0-1)
    private var progress: Double {
        guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
        return manager.seconds.seconds / runtime.seconds
    }

    var body: some View {
        if isVisible {
            miniBarContent
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(duration: 0.4), value: isVisible)
        }
    }

    private var miniBarContent: some View {
        Button {
            returnToPlayer()
        } label: {
            HStack(spacing: 16) {
                // Album art thumbnail
                albumArtThumbnail
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(trackTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.white)

                    if let artist = artistName {
                        Text(artist)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Play/Pause button
                Button {
                    manager.togglePlayPause()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)

                // Expand indicator
                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: 600)
            .background {
                // Glass background with progress indicator
                ZStack(alignment: .bottom) {
                    TransportBarBackground()

                    // Progress bar at bottom
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: geometry.size.width * progress, height: 2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .shadow(color: .black.opacity(0.4), radius: isFocused ? 20 : 10, y: 5)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
    }

    @ViewBuilder
    private var albumArtThumbnail: some View {
        if let imageURL = manager.item.imageURL(.primary, maxWidth: 120) {
            LazyImage(url: imageURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    placeholderArt
                }
            }
        } else {
            placeholderArt
        }
    }

    private var placeholderArt: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Image(systemName: "music.note")
                .font(.title2)
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private func returnToPlayer() {
        // Navigate back to full music player
        router.route(to: .videoPlayer(manager: manager))
    }
}
