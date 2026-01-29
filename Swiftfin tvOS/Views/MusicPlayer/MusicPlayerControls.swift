//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct MusicPlayerControls: View {

    @EnvironmentObject
    private var manager: MediaPlayerManager
    @EnvironmentObject
    private var containerState: MusicPlayerContainerState

    // MARK: - Skip State (multi-click)

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
    private var skipIndicatorText: String?
    @State
    private var skipIndicatorResetTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Skip indicator
            if let text = skipIndicatorText {
                Text(text)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10)
                    .transition(.scale.combined(with: .opacity))
                    .offset(y: -200)
            }

            VStack(spacing: 24) {
                // Progress bar
                MusicProgressBar()

                // Transport buttons
                transportButtons
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 40)
            .background {
                // Liquid Glass background
                RoundedRectangle(cornerRadius: 30)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 30)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    }
            }
            .opacity(containerState.isPresentingControls ? 1 : 0)
        }
        .animation(.easeOut(duration: 0.2), value: skipIndicatorText)
        .focusable()
        .onExitCommand {
            handleMenuPress()
        }
        .onMoveCommand { direction in
            containerState.showControls()
            switch direction {
            case .left:
                handleSkip(direction: .backward)
            case .right:
                handleSkip(direction: .forward)
            default:
                break
            }
        }
        .onPlayPauseCommand {
            containerState.showControls()
            manager.togglePlayPause()
        }
    }

    // MARK: - Transport Buttons

    private var transportButtons: some View {
        HStack(spacing: 60) {
            // Skip backward
            Button {
                handleSkip(direction: .backward)
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            // Play/Pause
            Button {
                manager.togglePlayPause()
            } label: {
                Image(systemName: manager.playbackRequestStatus == .playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            // Skip forward
            Button {
                handleSkip(direction: .forward)
            } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Menu Press Handler

    private func handleMenuPress() {
        if containerState.isPresentingControls {
            // First press hides controls
            withAnimation(.easeInOut(duration: 0.3)) {
                containerState.isPresentingControls = false
            }
        } else {
            // Second press exits
            containerState.shouldDismiss = true
        }
    }

    // MARK: - Skip Logic

    private func handleSkip(direction: SkipDirection) {
        containerState.showControls()

        switch direction {
        case .forward:
            forwardResetTask?.cancel()
            forwardClickCount = min(forwardClickCount + 1, skipAmounts.count)

            let skipAmount = skipAmounts[forwardClickCount - 1]
            manager.proxy?.jumpForward(skipAmount)
            skipIndicatorText = "+\(formatDuration(skipAmount.seconds))"

            forwardResetTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                forwardClickCount = 0
            }

        case .backward:
            backwardResetTask?.cancel()
            backwardClickCount = min(backwardClickCount + 1, skipAmounts.count)

            let skipAmount = skipAmounts[backwardClickCount - 1]
            manager.proxy?.jumpBackward(skipAmount)
            skipIndicatorText = "-\(formatDuration(skipAmount.seconds))"

            backwardResetTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                backwardClickCount = 0
            }
        }

        // Auto-hide skip indicator
        skipIndicatorResetTask?.cancel()
        skipIndicatorResetTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            skipIndicatorText = nil
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
