//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct MusicProgressBar: View {

    @EnvironmentObject
    private var manager: MediaPlayerManager

    private var progress: Double {
        guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
        let current = manager.seconds.seconds
        let total = runtime.seconds
        guard total > 0 else { return 0 }
        return current / total
    }

    private var currentTime: String {
        formatTime(manager.seconds.seconds)
    }

    private var remainingTime: String {
        guard let runtime = manager.item.runtime else { return "--:--" }
        let remaining = runtime.seconds - manager.seconds.seconds
        return "-" + formatTime(max(0, remaining))
    }

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            progressBar

            // Timestamps
            HStack {
                Text(currentTime)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .monospacedDigit()

                Spacer()

                Text(remainingTime)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .monospacedDigit()
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            let width = max(0, geometry.size.width)
            let clampedProgress = progress.isFinite ? max(0, min(1, progress)) : 0
            let progressWidth = width * clampedProgress

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 6)

                // Progress fill
                Capsule()
                    .fill(.white)
                    .frame(width: progressWidth, height: 6)

                // Current position indicator
                Circle()
                    .fill(.white)
                    .frame(width: 14, height: 14)
                    .offset(x: progressWidth - 7)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
        }
        .frame(height: 14)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}
