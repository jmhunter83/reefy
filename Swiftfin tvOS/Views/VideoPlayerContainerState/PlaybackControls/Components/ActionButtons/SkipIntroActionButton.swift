//
// Swiftfin is subject to terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct SkipIntro: View {

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            let activeIntroSegment = manager.item.activeSegment(at: manager.seconds)

            if isInMenu {
                // Show skip button in menu overlay
                Button(L10n.skipIntro, systemImage: VideoPlayerActionButton.skipIntro.systemImage) {
                    performSkip()
                }
                .disabled(activeIntroSegment == nil)
            } else {
                // Show skip button in transport bar
                Button(L10n.skipIntro, systemImage: VideoPlayerActionButton.skipIntro.systemImage) {
                    performSkip()
                }
                .disabled(activeIntroSegment == nil)
                .labelStyle(.iconOnly)
            }
        }

        private func performSkip() {
            guard let activeSegment = manager.item.activeSegment(at: manager.seconds) else { return }
            
            // Seek to the end of the intro segment
            manager.send(.set(seconds: activeSegment.end))
        }
    }
}
