//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct AutoPlay: View {

        /// Focus state passed from parent ActionButtons view
        let isFocused: Bool

        @Default(.VideoPlayer.autoPlayEnabled)
        private var isAutoPlayEnabled

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var systemImage: String {
            if isAutoPlayEnabled {
                "play.circle.fill"
            } else {
                "stop.circle"
            }
        }

        var body: some View {
            if isInMenu {
                // Inside overflow menu - use standard Button
                Button {
                    isAutoPlayEnabled.toggle()
                } label: {
                    Label(
                        L10n.autoPlay,
                        systemImage: systemImage
                    )

                    Text(isAutoPlayEnabled ? "On" : "Off")
                }
                .disabled(manager.queue == nil)
            } else {
                // In bar - use native focus wrapper
                TransportBarButton(isFocused: isFocused) {
                    isAutoPlayEnabled.toggle()
                } label: {
                    Image(systemName: systemImage)
                }
                .disabled(manager.queue == nil)
            }
        }
    }
}
