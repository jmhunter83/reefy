//
// Swiftfin is subject to the terms of the Mozilla Public
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
            // Intro skipper is not yet implemented
            // This button will be enabled once media segments API integration is complete
            Button(L10n.skipIntro, systemImage: VideoPlayerActionButton.skipIntro.systemImage) {
                // TODO: Implement intro skip functionality
            }
            .disabled(true) // Always disabled until feature is implemented
            .labelStyle(.iconOnly)
        }
    }
}
