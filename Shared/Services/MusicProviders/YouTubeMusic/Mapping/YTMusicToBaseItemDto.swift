//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// Mapping extensions to convert YouTube Music models to Jellyfin's BaseItemDto
///
/// BaseItemDto is Jellyfin's universal item type. By mapping YouTube Music models
/// to BaseItemDto, we can reuse existing UI components designed for Jellyfin.
///
/// Key mappings:
/// - YouTube `browseId` → BaseItemDto `id`
/// - YouTube `thumbnails` → BaseItemDto image tags (with custom handling)
/// - YouTube `videoId` → Stored in `externalUrls` for playback

// MARK: - Artist Mapping

extension YTMusicArtist {

    /// Convert to BaseItemDto
    func toBaseItemDto() -> BaseItemDto {
        var dto = BaseItemDto(
            id: id,
            name: name,
            type: .musicArtist
        )

        // Set overview from description if available
        dto.overview = description

        // Store subscriber count in custom data
        if let subscribers = subscriberCount {
            dto.taglines = [subscribers]
        }

        // Store YouTube Music URLs and thumbnails in providerIDs
        var providerIDs: [String: String] = [
            "YTMusic": "https://music.youtube.com/channel/\(id)",
        ]
        if let thumbnailURL = thumbnailURL {
            providerIDs["YTMusicThumb"] = thumbnailURL.absoluteString
        }
        dto.providerIDs = providerIDs

        return dto
    }
}

// MARK: - Album Mapping

extension YTMusicAlbum {

    /// Convert to BaseItemDto
    func toBaseItemDto() -> BaseItemDto {
        var dto = BaseItemDto(
            id: id,
            name: title,
            type: .musicAlbum
        )

        // Set album-specific properties
        if let year = year, let yearInt = Int(year) {
            dto.productionYear = yearInt
        }

        // Set artists
        dto.albumArtists = artists.map { artistRef in
            NameGuidPair(id: artistRef.id, name: artistRef.name)
        }

        dto.albumArtist = artists.first?.name

        // Set track count and duration
        dto.childCount = trackCount

        if let duration = duration {
            dto.taglines = [duration]
        }

        // Set album type in genres (Album, Single, EP)
        if type != .unknown {
            dto.genres = [type.rawValue]
        }

        // Set explicit flag in tags
        if isExplicit {
            dto.tags = ["Explicit"]
        }

        // Store playback IDs and thumbnails in providerIDs
        var providerIDs: [String: String] = [
            "YTMusic": "https://music.youtube.com/browse/\(id)",
        ]

        if let playlistId = playlistId {
            providerIDs["YTMusic_playlistId"] = playlistId
        }

        if let audioPlaylistId = audioPlaylistId {
            providerIDs["YTMusic_audioPlaylistId"] = audioPlaylistId
        }

        if let thumbnailURL = thumbnailURL {
            providerIDs["YTMusicThumb"] = thumbnailURL.absoluteString
        }

        dto.providerIDs = providerIDs

        return dto
    }
}

// MARK: - Track Mapping

extension YTMusicTrack {

    /// Convert to BaseItemDto
    func toBaseItemDto() -> BaseItemDto {
        var dto = BaseItemDto(
            id: videoId,
            name: title,
            type: .audio
        )

        // Set duration in ticks (1 tick = 100 nanoseconds = 0.0000001 seconds)
        // So seconds * 10,000,000 = ticks
        if let seconds = durationSeconds {
            dto.runTimeTicks = seconds * 10_000_000
        }

        // Set artists
        dto.artists = artists.map(\.name)
        dto.artistItems = artists.map { artistRef in
            NameGuidPair(id: artistRef.id, name: artistRef.name)
        }

        // Set album info
        if let albumRef = album {
            dto.album = albumRef.name
            dto.albumID = albumRef.id
        }

        // Set track number
        if let trackNum = trackNumber {
            dto.indexNumber = trackNum
        }

        // Set explicit flag
        if isExplicit {
            dto.tags = ["Explicit"]
        }

        // Store playback info and thumbnails in providerIDs
        var providerIDs: [String: String] = [
            "YTMusic_videoId": videoId,
            "YTMusic": "https://music.youtube.com/watch?v=\(videoId)",
        ]

        if let setVideoId = setVideoId {
            providerIDs["YTMusic_setVideoId"] = setVideoId
        }

        if let thumbnailURL = thumbnailURL {
            providerIDs["YTMusicThumb"] = thumbnailURL.absoluteString
        }

        dto.providerIDs = providerIDs

        return dto
    }
}

// MARK: - Playlist Mapping

extension YTMusicPlaylist {

    /// Convert to BaseItemDto
    func toBaseItemDto() -> BaseItemDto {
        var dto = BaseItemDto(
            id: id,
            name: title,
            type: .playlist
        )

        // Set description
        dto.overview = description

        // Set track count
        dto.childCount = trackCount

        // Set duration
        if let duration = duration {
            dto.taglines = [duration]
        }

        // Set author as album artist
        if let author = author {
            dto.albumArtist = author.name
            dto.albumArtists = [NameGuidPair(id: author.id, name: author.name)]
        }

        // Store URLs and thumbnails in providerIDs
        var providerIDs: [String: String] = [
            "YTMusic": "https://music.youtube.com/playlist?list=\(id)",
        ]
        if let thumbnailURL = thumbnailURL {
            providerIDs["YTMusicThumb"] = thumbnailURL.absoluteString
        }
        dto.providerIDs = providerIDs

        return dto
    }
}

// MARK: - Batch Conversion

extension Array where Element == YTMusicArtist {
    /// Convert array of artists to BaseItemDto array
    func toBaseItemDtos() -> [BaseItemDto] {
        map { $0.toBaseItemDto() }
    }
}

extension Array where Element == YTMusicAlbum {
    /// Convert array of albums to BaseItemDto array
    func toBaseItemDtos() -> [BaseItemDto] {
        map { $0.toBaseItemDto() }
    }
}

extension Array where Element == YTMusicTrack {
    /// Convert array of tracks to BaseItemDto array
    func toBaseItemDtos() -> [BaseItemDto] {
        map { $0.toBaseItemDto() }
    }
}

extension Array where Element == YTMusicPlaylist {
    /// Convert array of playlists to BaseItemDto array
    func toBaseItemDtos() -> [BaseItemDto] {
        map { $0.toBaseItemDto() }
    }
}

// MARK: - Helper Extensions for BaseItemDto

extension BaseItemDto {

    /// Check if this item came from YouTube Music
    var isFromYouTubeMusic: Bool {
        providerIDs?["YTMusic"] != nil
    }

    /// Get the YouTube Music thumbnail URL if available
    var ytMusicThumbnailURL: URL? {
        guard let urlString = providerIDs?["YTMusicThumb"] else { return nil }
        return URL(string: urlString)
    }

    /// Get the YouTube video ID for playback (for tracks)
    var ytMusicVideoId: String? {
        providerIDs?["YTMusic_videoId"]
    }

    /// Get the YouTube Music browse ID (for artists/albums)
    var ytMusicBrowseId: String? {
        id
    }
}
