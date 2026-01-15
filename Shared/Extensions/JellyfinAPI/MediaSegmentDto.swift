// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// MARK: - Media Segment Support for Intro Skipper
// Based on Jellyfin 10.10+ Media Segments API
// https://jellyfin.org/docs/general/server/metadata/media-segments/

public enum MediaSegmentType: String, CaseIterable {
    case intro = "Intro"
    case outro = "Outro"
    case commercial = "Commercial"
    case preview = "Preview"
    case recap = "Recap"
    
    public var displayName: String {
        switch self {
        case .intro: return L10n.intro
        case .outro: return L10n.outro
        case .commercial: return L10n.commercial
        case .preview: return L10n.preview
        case .recap: return L10n.recap
        }
    }
}

public struct MediaSegmentDto {
    public let start: TimeInterval
    public let end: TimeInterval
    public let type: MediaSegmentType
    
    public init(
        start: TimeInterval,
        end: TimeInterval,
        type: MediaSegmentType
    ) {
        self.start = start
        self.end = end
        self.type = type
    }
}

public struct MediaSegmentDtoQueryResult {
    public let items: [MediaSegmentDto]?
    public let startIndex: Int?
    public let totalRecordCount: Int?
    
    public init(
        items: [MediaSegmentDto]?,
        startIndex: Int? = nil,
        totalRecordCount: Int? = nil
    ) {
        self.items = items
        self.startIndex = startIndex
        self.totalRecordCount = totalRecordCount
    }
}

// MARK: - BaseItemDto Extension for Media Segments
extension BaseItemDto {
    
    /// Media segments associated with this item (Intro/Outro/etc.)
    /// Available in Jellyfin 10.10+ with Media Segment providers (e.g., Intro Skipper plugin)
    public var mediaSegments: [MediaSegmentDto]? {
        // This will be populated when the full item includes MediaSegments field
        // For now, this requires fetching via separate API call
        return nil // Will be implemented with API integration
    }
    
    /// Get intro segments for this item
    public var introSegments: [MediaSegmentDto] {
        return mediaSegments?.filter { $0.type == .intro } ?? []
    }
    
    /// Get outro segments for this item  
    public var outroSegments: [MediaSegmentDto] {
        return mediaSegments?.filter { $0.type == .outro } ?? []
    }
    
    /// Check if current playback time is within an intro segment
    public func isInIntroSegment(at time: TimeInterval) -> Bool {
        return introSegments.contains { $0.start <= time && $0.end >= time }
    }
    
    /// Check if current playback time is within an outro segment
    public func isInOutroSegment(at time: TimeInterval) -> Bool {
        return outroSegments.contains { $0.start <= time && $0.end >= time }
    }
    
    /// Get the active segment at the given time (if any)
    public func activeSegment(at time: TimeInterval) -> MediaSegmentDto? {
        return mediaSegments?.first { $0.start <= time && $0.end >= time }
    }
}

// MARK: - JellyfinClient Extension for Media Segments
extension JellyfinClient {
    
    /// Fetch media segments for a specific item
    /// This is the API endpoint that provides intro/outro segment data from plugins like Intro Skipper
    /// Available in Jellyfin 10.10+
    public func getMediaSegments(
        itemId: String,
        userId: String? = nil
    ) async throws -> MediaSegmentDtoQueryResult {
        
        // Construct the API endpoint path
        // Based on Jellyfin API: GET /Items/{itemId}/MediaSegments
        let path = "/Items/\(itemId)/MediaSegments"
        
        // Build the request
        let request = Request<MediaSegmentDtoQueryResult>(
            url: fullURL(with: path),
            method: .get
        )
        
        // Send the request and return the response
        let response = try await send(request)
        return response.value ?? MediaSegmentDtoQueryResult(items: nil)
    }
    
    /// Fetch media segments for the current user's item
    public func getMediaSegments(
        for itemId: String
    ) async throws -> MediaSegmentDtoQueryResult {
        return try await getMediaSegments(itemId: itemId, userId: nil)
    }
}
