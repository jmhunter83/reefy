//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct PlaybackProgress: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var progress: Double {
            guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
            let current = manager.seconds.seconds
            let total = runtime.seconds
            return current / total
        }

        var body: some View {
            VStack(spacing: 12) {
                // Non-interactive progress bar
                staticProgressBar

                // Timestamps
                SplitTimeStamp()
            }
        }

        private var staticProgressBar: some View {
            GeometryReader { geometry in
                let width = max(0, geometry.size.width)
                let clampedProgress = progress.isFinite ? max(0, min(1, progress)) : 0
                let progressWidth = width * clampedProgress

                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)

                    // Progress fill
                    Capsule()
                        .fill(.white)
                        .frame(width: progressWidth, height: 6)

                    // Chapter boundary gaps (overlaid on both tracks)
                    if let chapters = manager.item.fullChapterInfo,
                       let runtime = manager.item.runtime,
                       chapters.count > 1
                    {
                        ChapterTrackMask(chapters: chapters, runtime: runtime)
                            .frame(height: 12)
                    }

                    // Current position indicator (circle)
                    Circle()
                        .fill(.white)
                        .frame(width: 12, height: 12)
                        .offset(x: progressWidth - 6)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }
            .frame(height: 12)
        }
    }
}
