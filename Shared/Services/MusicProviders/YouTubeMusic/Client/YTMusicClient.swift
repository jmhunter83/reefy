//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Logging

/// HTTP client for YouTube Music API requests
///
/// This client handles all communication with YouTube Music's internal API,
/// including authentication headers, request formatting, and response parsing.
final class YTMusicClient {

    // MARK: - Properties

    let auth: YTMusicAuth
    private let session: URLSession
    private let logger = Logger.swiftfin()

    /// Visitor data extracted from initial page load
    /// Used to maintain session continuity
    private var visitorData: String?

    // MARK: - Initialization

    init(auth: YTMusicAuth, session: URLSession = .shared) {
        self.auth = auth
        self.session = session
    }

    // MARK: - Public API Methods

    /// Search YouTube Music for artists, albums, songs, etc.
    /// - Parameters:
    ///   - query: The search query
    ///   - filter: Optional filter to narrow results (artists, albums, songs, etc.)
    ///   - limit: Maximum number of results
    /// - Returns: Raw JSON response as dictionary
    func search(query: String, filter: SearchFilter? = nil, limit: Int = 20) async throws -> [String: Any] {
        var params: [String: Any] = ["query": query]

        if let filter = filter {
            params["params"] = filter.param
        }

        return try await post(endpoint: .search, params: params)
    }

    /// Browse content by ID (artist, album, playlist, etc.)
    /// - Parameter browseId: The YouTube Music browse ID
    /// - Returns: Raw JSON response as dictionary
    func browse(browseId: String) async throws -> [String: Any] {
        let params: [String: Any] = ["browseId": browseId]
        return try await post(endpoint: .browse, params: params)
    }

    /// Get user's library artists
    func getLibraryArtists(limit: Int = 25) async throws -> [String: Any] {
        try await browse(browseId: YTMusicHeaders.BrowseID.libraryArtists)
    }

    /// Get user's library albums
    func getLibraryAlbums(limit: Int = 25) async throws -> [String: Any] {
        try await browse(browseId: YTMusicHeaders.BrowseID.libraryAlbums)
    }

    /// Get user's liked songs
    func getLikedSongs() async throws -> [String: Any] {
        try await browse(browseId: YTMusicHeaders.BrowseID.likedSongs)
    }

    /// Get user's play history
    func getHistory() async throws -> [String: Any] {
        try await browse(browseId: YTMusicHeaders.BrowseID.history)
    }

    /// Get artist details and discography
    /// - Parameter artistId: The artist's channel/browse ID
    func getArtist(artistId: String) async throws -> [String: Any] {
        try await browse(browseId: artistId)
    }

    /// Get album details and track list
    /// - Parameter albumId: The album's browse ID
    func getAlbum(albumId: String) async throws -> [String: Any] {
        try await browse(browseId: albumId)
    }

    /// Get home feed/recommendations
    func getHome() async throws -> [String: Any] {
        try await browse(browseId: YTMusicHeaders.BrowseID.home)
    }

    // MARK: - Private Methods

    /// Perform a POST request to YouTube Music API
    private func post(endpoint: YTMusicHeaders.Endpoint, params: [String: Any]) async throws -> [String: Any] {
        let accessToken = auth.isAuthenticated ? try await auth.getValidAccessToken() : nil

        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"

        // Set headers
        let headers = YTMusicHeaders.standardHeaders(accessToken: accessToken)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Build request body
        let body = YTMusicHeaders.buildRequestBody(
            context: YTMusicHeaders.requestContext(visitorData: visitorData),
            params: params
        )

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        logger.debug("YTMusic API: POST \(endpoint.path)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw YTMusicError.invalidResponse
        }

        // Handle HTTP errors
        switch httpResponse.statusCode {
        case 200 ... 299:
            break
        case 401:
            throw YTMusicError.notAuthenticated
        case 403:
            throw YTMusicError.httpError(statusCode: 403, message: "Forbidden")
        case 429:
            throw YTMusicError.rateLimited
        default:
            throw YTMusicError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }

        // Parse JSON response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw YTMusicError.invalidResponse
        }

        // Extract visitor data if present (for session continuity)
        extractVisitorData(from: json)

        return json
    }

    /// Extract and store visitor data from response for future requests
    private func extractVisitorData(from json: [String: Any]) {
        if let responseContext = json["responseContext"] as? [String: Any],
           let visitorData = responseContext["visitorData"] as? String
        {
            self.visitorData = visitorData
        }
    }
}

// MARK: - Search Filters

extension YTMusicClient {

    /// Filters for narrowing search results to specific content types
    enum SearchFilter {
        case songs
        case videos
        case albums
        case artists
        case playlists
        case communityPlaylists
        case featuredPlaylists
        case uploads

        /// The param value sent to YouTube Music API
        var param: String {
            switch self {
            case .songs:
                return "EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D"
            case .videos:
                return "EgWKAQIQAWoKEAkQChAFEAMQBA%3D%3D"
            case .albums:
                return "EgWKAQIYAWoKEAkQChAFEAMQBA%3D%3D"
            case .artists:
                return "EgWKAQIgAWoKEAkQChAFEAMQBA%3D%3D"
            case .playlists:
                return "Eg-KAQwIABAAGAAgACgBMABqChAJEAoQBRADEAQ%3D"
            case .communityPlaylists:
                return "EgeKAQQoAEABagoQCRAKEAUQAxAE"
            case .featuredPlaylists:
                return "EgeKAQQoADgBagoQCRAKEAUQAxAE"
            case .uploads:
                return "EgWKAQIcAWoKEAkQChAFEAMQBA%3D%3D"
            }
        }
    }
}

// MARK: - Convenience Extensions

extension YTMusicClient {

    /// Search specifically for artists
    func searchArtists(query: String, limit: Int = 20) async throws -> [String: Any] {
        try await search(query: query, filter: .artists, limit: limit)
    }

    /// Search specifically for albums
    func searchAlbums(query: String, limit: Int = 20) async throws -> [String: Any] {
        try await search(query: query, filter: .albums, limit: limit)
    }

    /// Search specifically for songs
    func searchSongs(query: String, limit: Int = 20) async throws -> [String: Any] {
        try await search(query: query, filter: .songs, limit: limit)
    }

    /// Search specifically for playlists
    func searchPlaylists(query: String, limit: Int = 20) async throws -> [String: Any] {
        try await search(query: query, filter: .playlists, limit: limit)
    }
}
