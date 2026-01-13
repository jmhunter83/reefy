//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct AspectFill: View {

        var focusBinding: FocusState<VideoPlayerActionButton?>.Binding
        let buttonType: VideoPlayerActionButton

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        private var isAspectFilled: Bool {
            get { containerState.isAspectFilled }
            nonmutating set { containerState.isAspectFilled = newValue }
        }

        private var systemImage: String {
            if isAspectFilled {
                VideoPlayerActionButton.aspectFill.secondarySystemImage
            } else {
                VideoPlayerActionButton.aspectFill.systemImage
            }
        }

        var body: some View {
            if isInMenu {
                Button(L10n.aspectFill, systemImage: systemImage) {
                    isAspectFilled.toggle()
                }
            } else {
                TransportBarButton(focusBinding: focusBinding, buttonType: buttonType) {
                    isAspectFilled.toggle()
                } label: {
                    Image(systemName: systemImage)
                }
            }
        }
    }
}
