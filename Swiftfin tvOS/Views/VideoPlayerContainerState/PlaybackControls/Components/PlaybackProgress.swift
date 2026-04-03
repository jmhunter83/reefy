//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct PlaybackProgress: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>
        @EnvironmentObject
        private var focusGuide: FocusGuide

        private var totalSeconds: Double {
            manager.item.runtime?.seconds ?? 0
        }

        private var scrubbedSecondsBinding: Binding<Double> {
            Binding(
                get: { scrubbedSecondsBox.value.seconds },
                set: { scrubbedSecondsBox.value = .seconds($0) }
            )
        }

        var body: some View {
            VStack(spacing: 12) {
                CapsuleSlider(value: scrubbedSecondsBinding, total: totalSeconds)
                    .onEditingChanged { isEditing in
                        containerState.isScrubbing = isEditing
                    }
                    .frame(height: 12)

                SplitTimeStamp()
            }
            .focusGuide(focusGuide, tag: "playbackProgress", top: "actionButtons")
            .onReceive(manager.secondsBox.$value) { newSeconds in
                guard !containerState.isScrubbing else { return }
                scrubbedSecondsBox.value = newSeconds
            }
        }
    }
}
