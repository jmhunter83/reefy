//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct PlaybackProgress: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var chapters: [ChapterInfo.FullInfo]? {
            manager.supplements.first(where: { $0.id.contains("Chapters") }) as? MediaChaptersSupplement
                ? .init((manager.supplements.first(where: { $0.id.contains("Chapters") }) as! MediaChaptersSupplement).chapters)
                : nil
        }

        private var progress: Double {
            guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
            let current = manager.seconds.seconds
            let total = runtime.seconds
            return current / total
        }

        var body: some View {
            // Non-interactive progress bar
            staticProgressBar
        }

        private var staticProgressBar: some View {
            GeometryReader { geometry in
                let width = max(0, geometry.size.width)
                let clampedProgress = progress.isFinite ? max(0, min(1, progress)) : 0
                let progressWidth = width * clampedProgress

                ZStack(alignment: .leading) {
                    // Background track with glass effect on tvOS 18+
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 10)
                        .overlay {
                            if let chapters = (manager.supplements
                                .first(where: { $0.id.contains("Chapters") }) as? MediaChaptersSupplement)?.chapters,
                                let runtime = manager.item.runtime
                            {
                                ChapterTrackMask(chapters: chapters, runtime: runtime)
                                    .blendMode(.destinationOut)
                            }
                        }
                        .compositingGroup()

                    // Progress fill
                    Capsule()
                        .fill(.white)
                        .frame(width: progressWidth, height: 10)
                        .shadow(color: .white.opacity(0.5), radius: 6)

                    // Current position indicator (circle)
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .offset(x: progressWidth - 10)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                }
            }
            .frame(height: 20)
        }
    }
}
