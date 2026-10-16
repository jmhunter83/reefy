//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import UIKit

extension AVMediaPlayerProxy {

    /// Turns captions on when Closed Captions + SDH is on (Settings > Accessibility > Subtitles &
    /// Captioning) and no subtitle was picked.
    ///
    /// The proxy turns off AVPlayer's automatic media selection, so nothing else honors that
    /// setting. Live TV needs it most: broadcast CEA-608 shows up as a legible option here but
    /// isn't a Jellyfin stream, so the subtitle menu can't reach it. `AVPlayerLayer` draws the
    /// selection in the system caption style.
    func selectSystemCaptionsIfNeeded(for playerItem: AVPlayerItem, item: MediaPlayerItem) async {
        guard UIAccessibility.isClosedCaptioningEnabled,
              (item.selectedSubtitleStreamIndex ?? -1) < 0,
              let group = try? await playerItem.asset.loadMediaSelectionGroup(for: .legible),
              playerItem.currentMediaSelection.selectedMediaOption(in: group) == nil
        else { return }

        let accessible = AVMediaSelectionGroup.mediaSelectionOptions(
            from: group.options,
            withMediaCharacteristics: [.transcribesSpokenDialogForAccessibility]
        )
        let closedCaptions = group.options.filter { $0.mediaType == .closedCaption && !accessible.contains($0) }
        let candidates = accessible + closedCaptions

        let preferred = AVMediaSelectionGroup.mediaSelectionOptions(
            from: candidates,
            filteredAndSortedAccordingToPreferredLanguages: Locale.preferredLanguages
        )

        guard let option = preferred.first ?? candidates.first else { return }

        playerItem.select(option, in: group)
    }
}
