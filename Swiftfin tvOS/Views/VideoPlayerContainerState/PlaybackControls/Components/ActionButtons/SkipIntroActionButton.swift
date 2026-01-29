//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct SkipIntro: View {

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var currentSegment: MediaSegmentDto? {
            manager.currentSegment
        }

        private var segmentTitle: String {
            guard let segment = currentSegment, let type = segment.type else {
                return L10n.skipIntro
            }
            return "Skip \(type.displayTitle)"
        }

        var body: some View {
            Button(segmentTitle, systemImage: VideoPlayerActionButton.skipIntro.systemImage) {
                manager.skipCurrentSegment()
            }
            .disabled(currentSegment == nil)
            .labelStyle(.iconOnly)
        }
    }
}
