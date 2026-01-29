//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

enum VideoPlayerType: String, CaseIterable, Displayable, Storable {

    case swiftfin

    var displayTitle: String {
        "Reefy"
    }

    var directPlayProfiles: [DirectPlayProfile] {
        Self._swiftfinDirectPlayProfiles
    }

    var transcodingProfiles: [TranscodingProfile] {
        Self._swiftfinTranscodingProfiles
    }

    var subtitleProfiles: [SubtitleProfile] {
        Self._swiftfinSubtitleProfiles
    }
}
