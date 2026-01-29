//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct SplitTimestamp: View {

        enum Mode {
            case current
            case total
        }

        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

        let mode: Mode

        private var scrubbedSeconds: Duration {
            scrubbedSecondsBox.value
        }

        var body: some View {
            Group {
                switch mode {
                case .current:
                    Text(scrubbedSeconds, format: .runtime)
                case .total:
                    if let runtime = manager.item.runtime {
                        Text(.zero - (runtime - scrubbedSeconds), format: .runtime)
                    } else {
                        Text(verbatim: .emptyRuntime)
                    }
                }
            }
            .monospacedDigit()
        }
    }
}
