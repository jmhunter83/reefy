//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
@testable import Swiftfin_tvOS
import XCTest

/// Tests for ItemFilterCollection and related sort/filter types
final class ItemFilterTests: XCTestCase {

    // MARK: - Default Filter Collection

    func testDefaultSortBySortName() {
        let filters = ItemFilterCollection.default
        XCTAssertEqual(filters.sortBy.count, 1)
        XCTAssertEqual(filters.sortBy.first, .sortName)
    }

    func testDefaultSortOrderAscending() {
        let filters = ItemFilterCollection.default
        XCTAssertEqual(filters.sortOrder.count, 1)
        XCTAssertEqual(filters.sortOrder.first, .ascending)
    }

    func testDefaultHasNoFilters() {
        let filters = ItemFilterCollection.default
        XCTAssertFalse(filters.hasFilters)
    }

    func testDefaultHasNoQueryableFilters() {
        let filters = ItemFilterCollection.default
        XCTAssertFalse(filters.hasQueryableFilters)
    }

    func testDefaultActiveFilterCountIsZero() {
        let filters = ItemFilterCollection.default
        XCTAssertEqual(filters.activeFilterCount, 0)
    }

    // MARK: - Preset Filter Collections

    func testFavoritesPreset() {
        let filters = ItemFilterCollection.favorites
        XCTAssertTrue(filters.traits.contains(.isFavorite))
        XCTAssertTrue(filters.hasFilters)
    }

    func testRecentPreset() {
        let filters = ItemFilterCollection.recent
        XCTAssertEqual(filters.sortBy.first, .dateCreated)
        XCTAssertEqual(filters.sortOrder.first, .descending)
        XCTAssertTrue(filters.hasFilters)
    }

    // MARK: - Modified Filter Detection

    func testChangedSortByDetectedAsFiltered() {
        var filters = ItemFilterCollection.default
        filters.sortBy = [.premiereDate]
        XCTAssertTrue(filters.hasFilters)
        XCTAssertEqual(filters.activeFilterCount, 1)
    }

    func testChangedSortOrderDetectedAsFiltered() {
        var filters = ItemFilterCollection.default
        filters.sortOrder = [.descending]
        XCTAssertTrue(filters.hasFilters)
        XCTAssertEqual(filters.activeFilterCount, 1)
    }

    func testMultipleChangesCountCorrectly() {
        var filters = ItemFilterCollection.default
        filters.sortBy = [.premiereDate]
        filters.sortOrder = [.descending]
        XCTAssertEqual(filters.activeFilterCount, 2)
    }

    // MARK: - ItemSortBy Supported Cases

    func testSortBySupportedCasesNotEmpty() {
        XCTAssertFalse(ItemSortBy.supportedCases.isEmpty)
    }

    func testSortBySupportedCasesContainExpectedOptions() {
        let supported = ItemSortBy.supportedCases
        XCTAssertTrue(supported.contains(.name))
        XCTAssertTrue(supported.contains(.sortName))
        XCTAssertTrue(supported.contains(.premiereDate))
        XCTAssertTrue(supported.contains(.dateLastContentAdded))
        XCTAssertTrue(supported.contains(.random))
    }

    func testSortBySupportedCasesHaveDisplayTitles() {
        for sortOption in ItemSortBy.supportedCases {
            XCTAssertFalse(sortOption.displayTitle.isEmpty, "Missing display title for \(sortOption)")
        }
    }

    // MARK: - ItemSortOrder

    func testSortOrderAllCasesHasTwoOptions() {
        XCTAssertEqual(ItemSortOrder.allCases.count, 2)
    }

    func testSortOrderDisplayTitles() {
        XCTAssertFalse(ItemSortOrder.ascending.displayTitle.isEmpty)
        XCTAssertFalse(ItemSortOrder.descending.displayTitle.isEmpty)
    }

    // MARK: - AnyItemFilter Round-Trip

    func testSortByRoundTripThroughAnyItemFilter() {
        let original = ItemSortBy.premiereDate
        let anyFilter = original.asAnyItemFilter
        let roundTripped = ItemSortBy(from: anyFilter)
        XCTAssertEqual(original, roundTripped)
    }

    func testSortOrderRoundTripThroughAnyItemFilter() {
        let original = ItemSortOrder.descending
        let anyFilter = original.asAnyItemFilter
        let roundTripped = ItemSortOrder(from: anyFilter)
        XCTAssertEqual(original, roundTripped)
    }

    // MARK: - All Collection

    func testAllCollectionContainsSupportedSortOptions() {
        let all = ItemFilterCollection.all
        XCTAssertEqual(all.sortBy, ItemSortBy.supportedCases)
        XCTAssertEqual(all.sortOrder, ItemSortOrder.allCases)
    }
}
