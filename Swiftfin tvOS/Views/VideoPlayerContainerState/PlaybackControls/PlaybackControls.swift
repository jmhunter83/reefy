//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import PreferencesView
import SwiftUI
import VLCUI

extension VideoPlayer {

    struct PlaybackControls: View {

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

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var isPresentingSupplement: Bool {
            containerState.isPresentingSupplement
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        var body: some View {
            VStack {
                Spacer()

                if !isPresentingSupplement {
                    VStack(spacing: 16) {
                        NavigationBar()
                            .focusSection()

                        PlaybackProgress()
                    }
                    .padding(.horizontal, 60)
                    .padding(.bottom, 60)
                    .padding(.top, 30)
                    .background {
                        TransportBarBackground()
                    }
                }
            }
            .isVisible(isScrubbing || isPresentingOverlay)
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.4), value: isPresentingSupplement)
            .animation(.bouncy(duration: 0.25), value: isPresentingOverlay)
            .onChange(of: isPresentingOverlay) { _, isPresenting in
                if isPresenting {
                    DispatchQueue.main.asyncAfter(deadline: .now() + AnimationTiming.quickFocusDelay) {
                        focusGuide.transition(to: "actionButtons")
                    }
                }
            }
            .onReceive(onPressEvent) { press in
                switch press {
                case (.playPause, .began):
                    if !containerState.isPresentingOverlay {
                        withAnimation(.linear(duration: 0.25)) {
                            containerState.isPresentingOverlay = true
                        }
                    } else {
                        containerState.timer.poke()
                    }
                    manager.togglePlayPause()

                case (.menu, .began):
                    if isPresentingSupplement {
                        containerState.select(supplement: nil)
                    } else if containerState.supplementRecentlyDismissed {
                        containerState.supplementRecentlyDismissed = false
                    } else if isPresentingOverlay {
                        withAnimation(.linear(duration: 0.25)) {
                            containerState.isPresentingOverlay = false
                        }
                    } else {
                        manager.proxy?.stop()
                        router.dismiss()
                    }

                case (.menu, .ended), (.menu, .cancelled):
                    break

                default:
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
