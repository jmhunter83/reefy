//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import PreferencesView
import SwiftUI
import VLCUI

extension VideoPlayer {

    struct PlaybackControls: View {

        // since this view ignores safe area, it must
        // get safe area insets from parent views
        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var focusGuide: FocusGuide
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @OnPressEvent
        private var onPressEvent

        @Router
        private var router

        @State
        private var contentSize: CGSize = .zero
        @State
        private var effectiveSafeArea: EdgeInsets = .zero

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var isPresentingSupplement: Bool {
            containerState.isPresentingSupplement
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        @ViewBuilder
        private var titleOverlay: some View {
            if !isPresentingSupplement {
                VStack(alignment: .leading, spacing: 8) {
                    Text(manager.item.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 8)

                    if let year = manager.item.premiereDateYear {
                        Text(year)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.5), radius: 8)
                    }
                }
                .padding(.leading, 80)
                .padding(.top, 60)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .isVisible(isScrubbing || isPresentingOverlay)
            }
        }

        @ViewBuilder
        private var transportBar: some View {
            if !isPresentingSupplement {
                VStack(spacing: 16) {
                    // Action buttons row - right aligned, small icons
                    HStack {
                        Spacer()

                        NavigationBar.ActionButtons()
                            .focusSection()
                    }
                    .focusGuide(focusGuide, tag: "actionButtons")

                    // Progress bar with time labels
                    PlaybackProgress()
                        .focusGuide(focusGuide, tag: "playbackProgress")
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 30)
                .background {
                    TransportBarBackground()
                }
            }
        }

        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Title in top-left
                    titleOverlay

                    // Transport bar in bottom 15%
                    VStack {
                        Spacer()
                            .frame(minHeight: geometry.size.height * 0.85)

                        transportBar
                            .padding(.horizontal, 40)
                            .padding(.bottom, 60)
                            .isVisible(isScrubbing || isPresentingOverlay)
                    }
                }
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.4), value: isPresentingSupplement)
            .animation(.bouncy(duration: 0.25), value: isPresentingOverlay)
            .onReceive(onPressEvent) { press in
                switch press {
                case (.playPause, _):
                    // Show overlay and toggle play/pause
                    if !containerState.isPresentingOverlay {
                        withAnimation(.linear(duration: 0.25)) {
                            containerState.isPresentingOverlay = true
                        }
                    } else {
                        containerState.timer.poke()
                    }
                    manager.togglePlayPause()

                case (.menu, _):
                    if isPresentingSupplement {
                        containerState.selectedSupplement = nil
                    } else if isPresentingOverlay {
                        // First menu press hides overlay
                        withAnimation(.linear(duration: 0.25)) {
                            containerState.isPresentingOverlay = false
                        }
                    } else {
                        // Overlay hidden - exit playback
                        manager.proxy?.stop()
                        router.dismiss()
                    }

                default:
                    // Other buttons show overlay
                    if !containerState.isPresentingOverlay {
                        withAnimation(.linear(duration: 0.25)) {
                            containerState.isPresentingOverlay = true
                        }
                    } else {
                        containerState.timer.poke()
                    }
                }
            }
        }
    }
}
