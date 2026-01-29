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

        /// since this view ignores safe area, it must
        /// get safe area insets from parent views
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

        // MARK: - Multi-Click Skip State

        /// Skip amounts: [15s, 2min, 5min]
        private let skipAmounts: [Duration] = [
            .seconds(15),
            .seconds(120),
            .seconds(300),
        ]

        @State
        private var forwardClickCount: Int = 0
        @State
        private var backwardClickCount: Int = 0
        @State
        private var forwardResetTask: Task<Void, Never>?
        @State
        private var backwardResetTask: Task<Void, Never>?
        @State
        private var skipIndicatorResetTask: Task<Void, Never>?

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var isPresentingSupplement: Bool {
            containerState.isPresentingSupplement
        }

        private var transportBarContent: some View {
            VStack(spacing: 24) {
                // Timeline
                PlaybackProgress()
                    .padding(.horizontal, 20)

                // Controls and Timestamps
                HStack {
                    // Current position
                    SplitTimestamp(mode: .current)
                        .font(.headline)
                        .monospacedDigit()
                        .frame(width: 120, alignment: .leading)

                    Spacer()

                    // Primary Playback Buttons (Jump Back, Play/Pause, Jump Forward)
                    PlaybackButtons()

                    Spacer()

                    // Total/Remaining time
                    SplitTimestamp(mode: .total)
                        .font(.headline)
                        .monospacedDigit()
                        .frame(width: 120, alignment: .trailing)
                }
                .padding(.horizontal, 40)
            }
            .focusGuide(focusGuide, tag: "transportBar", top: "actionButtons")
        }

        @ViewBuilder
        private var transportBar: some View {
            if !isPresentingSupplement {
                transportBarContent
                    .padding(.vertical, 32)
                    .padding(.horizontal, 24)
                    .background {
                        TransportBarBackground()
                    }
            }
        }

        // MARK: - Skip Indicator

        @ViewBuilder
        private var skipIndicator: some View {
            if let text = containerState.skipIndicatorText {
                Text(text)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }

        var body: some View {
            GeometryReader { _ in
                ZStack {
                    // Navigation Bar (Title/Series) in top-left
                    VStack {
                        NavigationBar()
                            .padding(.leading, 80)
                            .padding(.top, 60)
                        Spacer()
                    }
                    .isVisible(isScrubbing || isPresentingOverlay)

                    // Skip indicator in center
                    skipIndicator
                        .animation(.easeOut(duration: 0.2), value: containerState.skipIndicatorText)

                    // Skip Intro button (floating pill)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            SkipIntroPill()
                        }
                        .padding(.bottom, 240) // Above utility row
                    }

                    // Bottom Controls Section
                    VStack(spacing: 32) {
                        Spacer()

                        // Utility Buttons Row (Subtitles, Audio, etc.)
                        NavigationBar.ActionButtons()

                        // Main Transport Bar (Progress + Playback)
                        transportBar
                            .padding(.horizontal, 60)
                            .padding(.bottom, 60)
                    }
                    .opacity(isScrubbing || isPresentingOverlay ? 1 : 0)
                    .disabled(!(isScrubbing || isPresentingOverlay))
                }
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.4), value: isPresentingSupplement)
            .animation(.bouncy(duration: 0.25), value: isPresentingOverlay)
            .onDisappear {
                // Clean up any active scrubbing timers when view disappears
                containerState.cleanupScrubbing()
                forwardResetTask?.cancel()
                backwardResetTask?.cancel()
                skipIndicatorResetTask?.cancel()
            }
            .onChange(of: isPresentingOverlay) { _, isPresenting in
                if isPresenting {
                    DispatchQueue.main.asyncAfter(deadline: .now() + AnimationTiming.skipIndicatorResetDelay) {
                        focusGuide.transition(to: "sideButtons")
                    }
                }
            }
            .onReceive(onPressEvent) { press in
                switch press {
                case (.playPause, .began):
                    // Show overlay and toggle play/pause
                    if !containerState.isPresentingOverlay {
                        withAnimation(.linear(duration: 0.25)) {
                            containerState.isPresentingOverlay = true
                        }
                    } else {
                        containerState.timer.poke()
                    }
                    manager.togglePlayPause()

                case (.leftArrow, .began):
                    // Skip backward with multi-click
                    handleSkip(direction: .backward)

                case (.rightArrow, .began):
                    // Skip forward with multi-click
                    handleSkip(direction: .forward)

                case (.menu, .began):
                    print(
                        "🎮 Menu press: isPresentingSupplement=\(isPresentingSupplement), isPresentingOverlay=\(isPresentingOverlay), supplementRecentlyDismissed=\(containerState.supplementRecentlyDismissed)"
                    )
                    if isPresentingSupplement {
                        print("🎮 Menu: Dismissing supplement")
                        containerState.select(supplement: nil)
                    } else if containerState.supplementRecentlyDismissed {
                        print("🎮 Menu: Clearing recent supplement dismissal flag")
                        // Supplement was just dismissed - clear flag but keep overlay visible
                        containerState.supplementRecentlyDismissed = false
                    } else if isPresentingOverlay {
                        print("🎮 Menu: Hiding overlay")
                        // First menu press hides overlay
                        withAnimation(.linear(duration: 0.25)) {
                            containerState.isPresentingOverlay = false
                        }
                    } else {
                        print("🎮 Menu: Exiting playback")
                        // Overlay hidden - exit playback
                        manager.proxy?.stop()
                        router.dismiss()
                    }

                case (.menu, .ended), (.menu, .cancelled):
                    // Explicitly ignore - prevent falling to default case which would re-show overlay
                    break

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

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        // MARK: - Multi-Click Skip Logic

        private func handleSkip(direction: SkipDirection) {
            // Show overlay if not visible
            if !containerState.isPresentingOverlay {
                withAnimation(.linear(duration: 0.25)) {
                    containerState.isPresentingOverlay = true
                }
            }
            containerState.timer.poke()

            switch direction {
            case .forward:
                forwardResetTask?.cancel()
                forwardClickCount = min(forwardClickCount + 1, skipAmounts.count)

                let skipAmount = skipAmounts[forwardClickCount - 1]
                manager.proxy?.jumpForward(skipAmount)
                containerState.skipIndicatorText = "+\(formatDuration(skipAmount.seconds))"

                forwardResetTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(600))
                    forwardClickCount = 0
                }

            case .backward:
                backwardResetTask?.cancel()
                backwardClickCount = min(backwardClickCount + 1, skipAmounts.count)

                let skipAmount = skipAmounts[backwardClickCount - 1]
                manager.proxy?.jumpBackward(skipAmount)
                containerState.skipIndicatorText = "−\(formatDuration(skipAmount.seconds))"

                backwardResetTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(600))
                    backwardClickCount = 0
                }
            }

            // Auto-hide skip indicator after delay
            skipIndicatorResetTask?.cancel()
            skipIndicatorResetTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                containerState.skipIndicatorText = nil
            }
        }

        private func formatDuration(_ seconds: Double) -> String {
            let totalSeconds = Int(seconds)
            let minutes = totalSeconds / 60
            let secs = totalSeconds % 60
            if minutes > 0 {
                return String(format: "%d:%02d", minutes, secs)
            } else {
                return ":\(String(format: "%02d", secs))"
            }
        }

        private enum SkipDirection {
            case forward
            case backward
        }
    }
}
