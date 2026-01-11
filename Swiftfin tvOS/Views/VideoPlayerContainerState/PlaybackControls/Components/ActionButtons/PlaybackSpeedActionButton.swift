//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct PlaybackSpeed: View {

        /// Focus state passed from parent ActionButtons view
        let isFocused: Bool

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        private let presetRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

        private func isCurrentRate(_ rate: Float) -> Bool {
            abs(manager.rate - rate) < 0.01
        }

        @ViewBuilder
        private var content: some View {
            ForEach(presetRates, id: \.self) { rate in
                Button {
                    manager.setRate(rate: rate)
                } label: {
                    if isCurrentRate(rate) {
                        Label(rate.formatted(.playbackRate), systemImage: "checkmark")
                    } else {
                        Text(rate.formatted(.playbackRate))
                    }
                }
            }
        }

        var body: some View {
            if isInMenu {
                // Inside overflow menu - use standard Menu
                Menu(
                    L10n.playbackSpeed,
                    systemImage: "speedometer"
                ) {
                    content
                }
            } else {
                // In bar - use native focus wrapper
                TransportBarMenu(L10n.playbackSpeed, isFocused: isFocused) {
                    Image(systemName: "speedometer")
                } content: {
                    Section(L10n.playbackSpeed) {
                        content
                    }
                }
            }
        }
    }
}
