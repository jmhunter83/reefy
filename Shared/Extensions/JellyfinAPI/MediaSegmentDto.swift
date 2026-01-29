//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// MARK: - MediaSegmentType Extensions

extension MediaSegmentType: Displayable {

    var displayTitle: String {
        switch self {
        case .commercial:
            "Commercial"
        case .preview:
            "Preview"
        case .recap:
            "Recap"
        case .outro:
            "Outro"
        case .intro:
            "Intro"
        case .unknown:
            L10n.unknown
        }
    }
}

// MARK: - MediaSegmentDto Extensions

public extension MediaSegmentDto {

    /// Convert startTicks to TimeInterval (seconds)
    var start: TimeInterval {
        guard let ticks = startTicks else { return 0 }
        return TimeInterval(ticks) / 10_000_000
    }

    /// Convert endTicks to TimeInterval (seconds)
    var end: TimeInterval {
        guard let ticks = endTicks else { return 0 }
        return TimeInterval(ticks) / 10_000_000
    }

    /// Duration of the segment in seconds
    var duration: TimeInterval {
        end - start
    }

    /// Check if a given time falls within this segment
    func contains(time: TimeInterval) -> Bool {
        time >= start && time <= end
    }
}
