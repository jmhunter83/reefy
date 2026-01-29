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

        private var canSkip: Bool {
            currentSegment != nil
        }

        var body: some View {
            Button(L10n.skipIntro, systemImage: VideoPlayerActionButton.skipIntro.systemImage) {
                guard let segment = currentSegment else { return }
                manager.proxy?.setSeconds(.seconds(segment.end))
            }
            .disabled(!canSkip)
            .labelStyle(.iconOnly)
        }
    }
}
