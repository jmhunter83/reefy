//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_tvOS
import XCTest

/// Tests for AppChangelog entries
final class AppChangelogTests: XCTestCase {

    // MARK: - Entry Existence

    func testVersion111EntryExists() {
        let entry = AppChangelog.entries["1.1.1"]
        XCTAssertNotNil(entry, "Changelog entry for 1.1.1 should exist")
    }

    func testVersion111HasItems() throws {
        let entry = AppChangelog.entries["1.1.1"]
        XCTAssertNotNil(entry)
        XCTAssertGreaterThan(try XCTUnwrap(entry?.items.count), 0, "Changelog should have at least one item")
    }

    // MARK: - Entry Content Validation

    func testAllEntriesHaveValidVersion() {
        for (key, entry) in AppChangelog.entries {
            XCTAssertEqual(key, entry.version, "Dictionary key should match entry version")
        }
    }

    func testAllItemsHaveNonEmptyFields() {
        for (_, entry) in AppChangelog.entries {
            for item in entry.items {
                XCTAssertFalse(item.icon.isEmpty, "Item icon should not be empty")
                XCTAssertFalse(item.title.isEmpty, "Item title should not be empty")
                XCTAssertFalse(item.description.isEmpty, "Item description should not be empty")
            }
        }
    }

    func testAllItemIconsAreValidSFSymbols() {
        for (_, entry) in AppChangelog.entries {
            for item in entry.items {
                // SF Symbols use dot-separated naming; basic format check
                XCTAssertTrue(
                    item.icon.contains(".") || item.icon.count > 2,
                    "Icon '\(item.icon)' doesn't look like a valid SF Symbol name"
                )
            }
        }
    }
}
