//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct Info: View {

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var infoSupplement: MediaInfoSupplement? {
            MediaInfoSupplement(item: manager.item)
        }

        var body: some View {
            if isInMenu {
                Button {
                    if let supplement = infoSupplement {
                        containerState.select(supplement: supplement, isGuest: true)
                    }
                } label: {
                    Label("Information", systemImage: "info.circle")
                }
            } else {
                TransportBarButton {
                    if let supplement = infoSupplement {
                        containerState.select(supplement: supplement, isGuest: true)
                    }
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
    }
}
