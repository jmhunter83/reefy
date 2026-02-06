//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_tvOS
import XCTest

/// Tests for PlaybackBitrate safety margin and configuration
final class PlaybackBitrateTests: XCTestCase {

    // MARK: - Bitrate Enum Tests

    func testAutoRawValueIsZero() {
        XCTAssertEqual(PlaybackBitrate.auto.rawValue, 0)
    }

    func testMaxRawValue() {
        XCTAssertEqual(PlaybackBitrate.max.rawValue, 360_000_000)
    }

    func testNonAutoReturnsRawValue() async throws {
        let bitrate = try await PlaybackBitrate.mbps20.getMaxBitrate()
        XCTAssertEqual(bitrate, 20_000_000)
    }

    func testAllCasesHaveDisplayTitles() {
        for bitrate in PlaybackBitrate.allCases {
            XCTAssertFalse(bitrate.displayTitle.isEmpty, "Display title should not be empty for \(bitrate)")
        }
    }

    func testBitrateOrdering() {
        // Verify bitrates are ordered from auto -> max -> descending
        let values = PlaybackBitrate.allCases.map(\.rawValue)

        // auto is 0, max is highest, rest descend
        XCTAssertEqual(values.first, 0) // auto
        XCTAssertEqual(values[1], 360_000_000) // max

        // From index 2 onward, values should decrease
        for i in 2 ..< values.count - 1 {
            XCTAssertGreaterThan(values[i], values[i + 1], "Bitrate at index \(i) should be greater than \(i + 1)")
        }
    }

    func testLowestBitrate() {
        XCTAssertEqual(PlaybackBitrate.kbps420.rawValue, 420_000)
    }
}
