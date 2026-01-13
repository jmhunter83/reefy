//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct PlayPreviousItem: View {

        var focusBinding: FocusState<VideoPlayerActionButton?>.Binding
        let buttonType: VideoPlayerActionButton

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            if let queue = manager.queue {
                PlayPreviousItemContent(
                    queue: queue,
                    isInMenu: isInMenu,
                    focusBinding: focusBinding,
                    buttonType: buttonType
                )
            }
        }
    }

    private struct PlayPreviousItemContent: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        var queue: AnyMediaPlayerQueue

        let isInMenu: Bool
        var focusBinding: FocusState<VideoPlayerActionButton?>.Binding
        let buttonType: VideoPlayerActionButton

        private func playPrevious() {
            guard let previousItem = queue.previousItem else { return }
            manager.playNewItem(provider: previousItem)
        }

        var body: some View {
            if isInMenu {
                Button(L10n.playPreviousItem, systemImage: VideoPlayerActionButton.playPreviousItem.systemImage) {
                    playPrevious()
                }
                .disabled(queue.previousItem == nil)
            } else {
                TransportBarButton(focusBinding: focusBinding, buttonType: buttonType) {
                    playPrevious()
                } label: {
                    Image(systemName: VideoPlayerActionButton.playPreviousItem.systemImage)
                }
                .disabled(queue.previousItem == nil)
            }
        }
    }
}
