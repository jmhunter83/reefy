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

        var focusBinding: FocusState<VideoPlayerActionButton?>.Binding
        let buttonType: VideoPlayerActionButton

        @Default(.VideoPlayer.autoPlayEnabled)
        private var isAutoPlayEnabled

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var systemImage: String {
            isAutoPlayEnabled ? "play.circle.fill" : "stop.circle"
        }

        var body: some View {
            if isInMenu {
                Button {
                    isAutoPlayEnabled.toggle()
                } label: {
                    Label(L10n.autoPlay, systemImage: systemImage)
                    Text(isAutoPlayEnabled ? "On" : "Off")
                }
                .disabled(manager.queue == nil)
            } else {
                TransportBarButton(focusBinding: focusBinding, buttonType: buttonType) {
                    isAutoPlayEnabled.toggle()
                } label: {
                    Image(systemName: systemImage)
                }
                .disabled(manager.queue == nil)
            }
        }
    }
}
