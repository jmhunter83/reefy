//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension VideoPlayer.PlaybackControls.PlaybackProgress {

    /// Creates gaps in the progress bar at chapter boundaries.
    /// Uses inverse mask technique for a cleaner visual than overlay tick marks.
    struct ChapterTrackMask: View {

        let chapters: [ChapterInfo.FullInfo]
        let runtime: Duration

        private var unitPoints: [Double] {
            chapters.compactMap { chapter in
                guard let startSeconds = chapter.chapterInfo.startSeconds,
                      startSeconds > .zero,
                      runtime > .zero
                else {
                    return nil
                }

                return startSeconds.seconds / runtime.seconds
            }
        }

        var body: some View {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    ForEach(unitPoints, id: \.self) { unitPoint in
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 3)
                            .offset(x: proxy.size.width * unitPoint - 1.5)
                    }
                }
            }
        }
    }
}
