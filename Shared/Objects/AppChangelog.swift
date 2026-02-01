//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct ChangelogEntry {
    let version: String
    let items: [ChangelogItem]
}

struct ChangelogItem {
    let icon: String
    let title: String
    let description: String
}

enum AppChangelog {
    static let entries: [String: ChangelogEntry] = [
        "1.2.0": ChangelogEntry(
            version: "1.2.0",
            items: [
                ChangelogItem(
                    icon: "lock.shield",
                    title: "Local Server Support",
                    description: "New per-server setting to allow connections to local Jellyfin servers using HTTP or self-signed certificates."
                ),
                ChangelogItem(
                    icon: "exclamationmark.bubble",
                    title: "Better Error Messages",
                    description: "Clearer feedback when connection issues occur, with suggestions to help resolve them."
                ),
            ]
        ),
    ]

    static var current: ChangelogEntry? {
        guard let version = Bundle.main.appVersion else { return nil }
        return entries[version]
    }
}
