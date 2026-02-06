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
        "1.1.2": ChangelogEntry(
            version: "1.1.2",
            items: [
                ChangelogItem(
                    icon: "ant.fill",
                    title: "Bug Fixes",
                    description: "Resolved various issues and improved app stability."
                ),
                ChangelogItem(
                    icon: "speedometer",
                    title: "Performance Improvements",
                    description: "Enhanced responsiveness and reduced resource usage."
                ),
            ]
        ),
        "1.1.1": ChangelogEntry(
            version: "1.1.1",
            items: [
                ChangelogItem(
                    icon: "music.note.list",
                    title: "Music Playback",
                    description: "Browse albums, dedicated player with background audio."
                ),
                ChangelogItem(
                    icon: "forward.end.alt",
                    title: "Skip Intro",
                    description: "Detects intro and outro segments with skip buttons."
                ),
                ChangelogItem(
                    icon: "line.3.horizontal.decrease",
                    title: "Library Sorting",
                    description: "Sort by name, date, or random from the toolbar."
                ),
                ChangelogItem(
                    icon: "wrench.and.screwdriver",
                    title: "Stability & Performance",
                    description: "Fixed auth issues, smoother buffering, crash prevention."
                ),
            ]
        ),
    ]

    static var current: ChangelogEntry? {
        guard let version = Bundle.main.appVersion else { return nil }
        return entries[version]
    }
}
