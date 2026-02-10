//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_tvOS
import XCTest

/// Tests for MediaError
final class MediaErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testNoPlayableSourceDescription() throws {
        let error = MediaError.noPlayableSource
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(try XCTUnwrap(error.errorDescription?.contains("playable")))
    }

    func testUnsupportedFormatWithFormat() throws {
        let error = MediaError.unsupportedFormat(format: "HEVC")
        XCTAssertTrue(try XCTUnwrap(error.errorDescription?.contains("HEVC")))
    }

    func testUnsupportedFormatWithoutFormat() throws {
        let error = MediaError.unsupportedFormat(format: nil)
        XCTAssertTrue(try XCTUnwrap(error.errorDescription?.contains("format")))
    }

    func testItemNotFoundWithId() throws {
        let error = MediaError.itemNotFound(itemId: "abc123")
        XCTAssertTrue(try XCTUnwrap(error.errorDescription?.contains("abc123")))
    }

    func testItemNotFoundWithoutId() throws {
        let error = MediaError.itemNotFound(itemId: nil)
        XCTAssertTrue(try XCTUnwrap(error.errorDescription?.contains("not found")))
    }

    // MARK: - Error Title Tests

    func testNoPlayableSourceTitle() {
        XCTAssertEqual(MediaError.noPlayableSource.errorTitle, L10n.mediaErrorTitleCannotPlay)
    }

    func testTranscodingFailedTitle() {
        XCTAssertEqual(MediaError.transcodingFailed(reason: nil).errorTitle, L10n.mediaErrorTranscoding)
    }

    func testStreamEndedTitle() {
        XCTAssertEqual(MediaError.streamEnded.errorTitle, L10n.mediaErrorPlayback)
    }

    func testItemNotFoundTitle() {
        XCTAssertEqual(MediaError.itemNotFound(itemId: nil).errorTitle, L10n.mediaErrorItemError)
    }

    func testSessionExpiredTitle() {
        XCTAssertEqual(MediaError.sessionExpired.errorTitle, L10n.mediaErrorSessionError)
    }

    // MARK: - Retryability Tests

    func testTranscodingFailedIsRetryable() {
        XCTAssertTrue(MediaError.transcodingFailed(reason: nil).isRetryable)
    }

    func testStreamEndedIsRetryable() {
        XCTAssertTrue(MediaError.streamEnded.isRetryable)
    }

    func testLoadFailedIsRetryable() {
        XCTAssertTrue(MediaError.loadFailed(reason: nil).isRetryable)
    }

    func testSessionExpiredIsRetryable() {
        XCTAssertTrue(MediaError.sessionExpired.isRetryable)
    }

    func testNoPlayableSourceIsNotRetryable() {
        XCTAssertFalse(MediaError.noPlayableSource.isRetryable)
    }

    func testUnsupportedFormatIsNotRetryable() {
        XCTAssertFalse(MediaError.unsupportedFormat(format: nil).isRetryable)
    }

    func testItemNotFoundIsNotRetryable() {
        XCTAssertFalse(MediaError.itemNotFound(itemId: nil).isRetryable)
    }

    func testNotPlayableIsNotRetryable() {
        XCTAssertFalse(MediaError.notPlayable.isRetryable)
    }

    // MARK: - Hashable Conformance Tests

    func testErrorsAreHashable() {
        var set = Set<MediaError>()
        set.insert(.noPlayableSource)
        set.insert(.streamEnded)
        set.insert(.noPlayableSource) // Duplicate

        XCTAssertEqual(set.count, 2)
    }

    func testDifferentItemNotFoundErrorsAreDistinct() {
        let error1 = MediaError.itemNotFound(itemId: "abc")
        let error2 = MediaError.itemNotFound(itemId: "xyz")

        XCTAssertNotEqual(error1, error2)
    }

    // MARK: - SystemImageable Tests

    func testSystemImageForPlaybackErrors() {
        XCTAssertFalse(MediaError.noPlayableSource.systemImage.isEmpty)
        XCTAssertFalse(MediaError.unsupportedFormat(format: nil).systemImage.isEmpty)
        XCTAssertFalse(MediaError.transcodingFailed(reason: nil).systemImage.isEmpty)
        XCTAssertFalse(MediaError.streamEnded.systemImage.isEmpty)
        XCTAssertFalse(MediaError.loadFailed(reason: nil).systemImage.isEmpty)
    }

    func testSystemImageForItemErrors() {
        XCTAssertFalse(MediaError.itemNotFound(itemId: nil).systemImage.isEmpty)
        XCTAssertFalse(MediaError.noMediaInfo.systemImage.isEmpty)
        XCTAssertFalse(MediaError.notPlayable.systemImage.isEmpty)
    }

    func testSystemImageForSessionErrors() {
        XCTAssertFalse(MediaError.sessionCreationFailed.systemImage.isEmpty)
        XCTAssertFalse(MediaError.sessionExpired.systemImage.isEmpty)
        XCTAssertFalse(MediaError.reportingFailed.systemImage.isEmpty)
    }

    // MARK: - Recovery Suggestion Tests

    func testRecoverySuggestionExists() {
        XCTAssertNotNil(MediaError.noPlayableSource.recoverySuggestion)
        XCTAssertNotNil(MediaError.sessionExpired.recoverySuggestion)
        XCTAssertNotNil(MediaError.transcodingFailed(reason: nil).recoverySuggestion)
    }

    func testNotPlayableHasNoRecoverySuggestion() {
        XCTAssertNil(MediaError.notPlayable.recoverySuggestion)
    }
}
