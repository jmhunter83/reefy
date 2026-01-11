//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct PlayNextItem: View {

        /// Focus state passed from parent ActionButtons view
        let isFocused: Bool

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            if let queue = manager.queue {
                _PlayNextItem(queue: queue, isInMenu: isInMenu, isFocused: isFocused)
            }
        }
    }

    private struct _PlayNextItem: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        var queue: AnyMediaPlayerQueue

        let isInMenu: Bool
        let isFocused: Bool

        var body: some View {
            if isInMenu {
                // Inside overflow menu - use standard Button
                Button(
                    L10n.playNextItem,
                    systemImage: VideoPlayerActionButton.playNextItem.systemImage
                ) {
                    guard let nextItem = queue.nextItem else { return }
                    manager.playNewItem(provider: nextItem)
                }
                .disabled(queue.nextItem == nil)
            } else {
                // In bar - use native focus wrapper
                TransportBarButton(isFocused: isFocused) {
                    guard let nextItem = queue.nextItem else { return }
                    manager.playNewItem(provider: nextItem)
                } label: {
                    Image(systemName: VideoPlayerActionButton.playNextItem.systemImage)
                }
                .disabled(queue.nextItem == nil)
            }
        }
    }
}
