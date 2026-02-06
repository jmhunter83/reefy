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
        "1.1.1": ChangelogEntry(
            version: "1.1.1",
            items: [
                ChangelogItem(
                    icon: "music.note.list",
                    title: "Music Playback",
                    description: "Browse albums and tracks, with a dedicated music player featuring skip, shuffle, repeat, background audio, and ReplayGain normalization."
                ),
                ChangelogItem(
                    icon: "forward.end.alt",
                    title: "Skip Intro & Segments",
                    description: "Automatically detects intro and outro segments from your Jellyfin server and shows skip buttons during playback."
                ),
                ChangelogItem(
                    icon: "line.3.horizontal.decrease",
                    title: "Library Sorting",
                    description: "Sort your libraries by name, premiere date, date added, or random order with ascending/descending options."
                ),
                ChangelogItem(
                    icon: "checkmark.circle",
                    title: "Fixed Authentication",
                    description: "Resolved critical issue where users could sign in but couldn't access their libraries. All server connections now work reliably."
                ),
                ChangelogItem(
                    icon: "waveform.badge.magnifyingglass",
                    title: "Smoother Playback",
                    description: "Improved buffering tolerance for VPN and proxy connections, smarter bitrate detection, and fixes for silent audio and phantom playback."
                ),
                ChangelogItem(
                    icon: "checkmark.shield",
                    title: "Enhanced Security",
                    description: "Removed global ATS bypass, HTTPS exceptions now scoped to local network only. Systematic crash prevention across the app."
                ),
                ChangelogItem(
                    icon: "arrow.triangle.2.circlepath",
                    title: "VLCKit 3.7.2",
                    description: "Updated video engine with upstream codec and stability improvements."
                ),
            ]
        ),
    ]

    static var current: ChangelogEntry? {
        guard let version = Bundle.main.appVersion else { return nil }
        return entries[version]
    }
}
