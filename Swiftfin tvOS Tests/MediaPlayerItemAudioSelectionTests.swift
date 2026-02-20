//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
@testable import Swiftfin_tvOS
import XCTest

/// Regression tests for initial audio stream selection.
@MainActor
final class MediaPlayerItemAudioSelectionTests: XCTestCase {

    private let testURL = URL(string: "https://example.com/video")!

    private func makeStream(index: Int, type: MediaStreamType, language: String? = nil, displayTitle: String? = nil) -> MediaStream {
        var stream = MediaStream()
        stream.index = index
        stream.type = type
        stream.language = language
        stream.displayTitle = displayTitle
        return stream
    }

    private func makeMediaSource(defaultAudioStreamIndex: Int?, audioLanguages: [String]) -> MediaSourceInfo {
        var mediaStreams: [MediaStream] = [
            makeStream(index: 0, type: .video),
        ]

        for (offset, language) in audioLanguages.enumerated() {
            mediaStreams.append(
                makeStream(index: offset + 1, type: .audio, language: language, displayTitle: language)
            )
        }

        var mediaSource = MediaSourceInfo()
        mediaSource.transcodingURL = nil
        mediaSource.mediaStreams = mediaStreams
        mediaSource.defaultAudioStreamIndex = defaultAudioStreamIndex
        return mediaSource
    }

    private func makeItem(mediaSource: MediaSourceInfo) -> MediaPlayerItem {
        .init(
            baseItem: BaseItemDto(),
            mediaSource: mediaSource,
            playSessionID: "test-session",
            url: testURL
        )
    }

    func testSelectsFirstAudioWhenDefaultIsNil() {
        let originalPreferredLanguage = Defaults[.VideoPlayer.Audio.preferredLanguage]
        defer { Defaults[.VideoPlayer.Audio.preferredLanguage] = originalPreferredLanguage }
        Defaults[.VideoPlayer.Audio.preferredLanguage] = "zzz"

        let mediaSource = makeMediaSource(defaultAudioStreamIndex: nil, audioLanguages: ["eng", "spa"])
        let item = makeItem(mediaSource: mediaSource)

        XCTAssertEqual(item.audioStreams.count, 2)
        XCTAssertNotNil(item.selectedAudioStreamIndex)
        XCTAssertGreaterThanOrEqual(item.selectedAudioStreamIndex ?? -1, 0)
        XCTAssertEqual(item.selectedAudioStreamIndex, item.audioStreams.first?.index)
    }

    func testSelectsDefaultAudioWhenValid() {
        let originalPreferredLanguage = Defaults[.VideoPlayer.Audio.preferredLanguage]
        defer { Defaults[.VideoPlayer.Audio.preferredLanguage] = originalPreferredLanguage }
        Defaults[.VideoPlayer.Audio.preferredLanguage] = "zzz"

        let mediaSource = makeMediaSource(defaultAudioStreamIndex: 2, audioLanguages: ["eng", "spa"])
        let item = makeItem(mediaSource: mediaSource)

        XCTAssertEqual(item.audioStreams.count, 2)
        XCTAssertEqual(item.selectedAudioStreamIndex, 2)
    }

    func testSelectsPreferredLanguageOverDefault() {
        let originalPreferredLanguage = Defaults[.VideoPlayer.Audio.preferredLanguage]
        defer { Defaults[.VideoPlayer.Audio.preferredLanguage] = originalPreferredLanguage }
        Defaults[.VideoPlayer.Audio.preferredLanguage] = "spa"

        let mediaSource = makeMediaSource(defaultAudioStreamIndex: 1, audioLanguages: ["eng", "spa"])
        let item = makeItem(mediaSource: mediaSource)

        XCTAssertEqual(item.audioStreams.count, 2)
        XCTAssertEqual(item.selectedAudioStreamIndex, 2)
    }

    func testFallsBackWhenDefaultInvalid() {
        let originalPreferredLanguage = Defaults[.VideoPlayer.Audio.preferredLanguage]
        defer { Defaults[.VideoPlayer.Audio.preferredLanguage] = originalPreferredLanguage }
        Defaults[.VideoPlayer.Audio.preferredLanguage] = "zzz"

        let mediaSource = makeMediaSource(defaultAudioStreamIndex: 99, audioLanguages: ["eng", "spa"])
        let item = makeItem(mediaSource: mediaSource)

        XCTAssertEqual(item.audioStreams.count, 2)
        XCTAssertNotNil(item.selectedAudioStreamIndex)
        XCTAssertGreaterThanOrEqual(item.selectedAudioStreamIndex ?? -1, 0)
        XCTAssertEqual(item.selectedAudioStreamIndex, item.audioStreams.first?.index)
    }
}
