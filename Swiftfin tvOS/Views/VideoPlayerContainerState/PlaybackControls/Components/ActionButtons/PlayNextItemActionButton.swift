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

        var focusBinding: FocusState<VideoPlayerActionButton?>.Binding
        let buttonType: VideoPlayerActionButton

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            if let queue = manager.queue {
                PlayNextItemContent(
                    queue: queue,
                    isInMenu: isInMenu,
                    focusBinding: focusBinding,
                    buttonType: buttonType
                )
            }
        }
    }

    private struct PlayNextItemContent: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        var queue: AnyMediaPlayerQueue

        let isInMenu: Bool
        var focusBinding: FocusState<VideoPlayerActionButton?>.Binding
        let buttonType: VideoPlayerActionButton

        private func playNext() {
            guard let nextItem = queue.nextItem else { return }
            manager.playNewItem(provider: nextItem)
        }

        var body: some View {
            if isInMenu {
                Button(L10n.playNextItem, systemImage: VideoPlayerActionButton.playNextItem.systemImage) {
                    playNext()
                }
                .disabled(queue.nextItem == nil)
            } else {
                TransportBarButton(focusBinding: focusBinding, buttonType: buttonType) {
                    playNext()
                } label: {
                    Image(systemName: VideoPlayerActionButton.playNextItem.systemImage)
                }
                .disabled(queue.nextItem == nil)
            }
        }
    }
}
