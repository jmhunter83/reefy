//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI
import Logging

/// YouTube Music implementation of MusicProvider
///
/// This provider enables access to YouTube Music content through the MusicProvider interface,
/// allowing the app to display YouTube Music artists, albums, and tracks using existing UI.
///
/// ## Authentication
/// Uses OAuth 2.0 Device Flow for tvOS authentication.
/// Call `startAuthentication()` to begin the flow, which will provide a code
/// to display to the user.
///
/// ## Usage
/// ```swift
/// let provider = YouTubeMusicProvider()
///
/// // Check if authenticated
/// if !provider.isAuthenticated {
///     let deviceCode = try await provider.startAuthentication()
///     // Display deviceCode.userCode and deviceCode.verificationUrl to user
///     await provider.awaitAuthentication()
/// }
///
/// // Use the provider
/// let artists = try await provider.getArtists(limit: 20)
/// ```
public final class YouTubeMusicProvider: MusicProvider, ObservableObject {

    // MARK: - MusicProvider Properties

    public let id = "youtube-music"
    public let displayName = "YouTube Music"
    public let requiresAuth = true

    public var isAuthenticated: Bool {
        auth.isAuthenticated
    }

    // MARK: - Published State

    @Published
    public private(set) var authState: YTMusicAuth.AuthState = .idle

    // MARK: - Private Properties

    private let auth: YTMusicAuth
    private let client: YTMusicClient
    private let logger = Logger.swiftfin()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init() {
        self.auth = YTMusicAuth()
        self.client = YTMusicClient(auth: auth)

        // Observe auth state changes
        auth.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.authState = state
            }
            .store(in: &cancellables)
    }

    /// Initialize with custom auth and client (for testing)
    init(auth: YTMusicAuth, client: YTMusicClient) {
        self.auth = auth
        self.client = client

        auth.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.authState = state
            }
            .store(in: &cancellables)
    }

    // MARK: - Authentication

    /// Start the OAuth device flow authentication
    /// - Returns: Bridge code response with user code and verification URL
    @MainActor
    public func startAuthentication() async throws -> YTMusicAuth.BridgeCodeResponse {
        try await auth.startAuthentication()

        guard case let .awaitingUserAction(deviceCode) = auth.state else {
            throw YTMusicError.unknown(message: "Failed to get device code")
        }

        return deviceCode
    }

    /// Begin polling for authentication completion
    /// Call this after displaying the device code to the user
    @MainActor
    public func awaitAuthentication() async {
        await auth.startPolling()
    }

    /// Cancel the current authentication flow
    @MainActor
    public func cancelAuthentication() {
        auth.cancelAuthentication()
    }

    /// Sign out and clear credentials
    @MainActor
    public func signOut() {
        auth.signOut()
    }

    // MARK: - MusicProvider Implementation

    public func getArtists(limit: Int?) async throws -> [BaseItemDto] {
        guard isAuthenticated else {
            throw MusicProviderError.notAuthenticated
        }

        do {
            let artists = try await client.fetchLibraryArtists(limit: limit ?? 25)
            return artists.toBaseItemDtos()
        } catch let error as YTMusicError {
            throw mapError(error)
        }
    }

    public func getAlbums(artistID: String?, limit: Int?) async throws -> [BaseItemDto] {
        guard isAuthenticated else {
            throw MusicProviderError.notAuthenticated
        }

        do {
            if let artistID = artistID {
                // Get albums for specific artist
                let albums = try await client.fetchArtistAlbums(artistId: artistID)
                return albums.toBaseItemDtos()
            } else {
                // Get library albums
                let albums = try await client.fetchLibraryAlbums(limit: limit ?? 25)
                return albums.toBaseItemDtos()
            }
        } catch let error as YTMusicError {
            throw mapError(error)
        }
    }

    public func getTracks(albumID: String) async throws -> [BaseItemDto] {
        do {
            let (_, tracks) = try await client.fetchAlbum(id: albumID)
            return tracks.toBaseItemDtos()
        } catch let error as YTMusicError {
            throw mapError(error)
        }
    }

    public func getRecentlyPlayed(limit: Int) async throws -> [BaseItemDto] {
        guard isAuthenticated else {
            throw MusicProviderError.notAuthenticated
        }

        do {
            let tracks = try await client.fetchHistory(limit: limit)
            return tracks.toBaseItemDtos()
        } catch let error as YTMusicError {
            throw mapError(error)
        }
    }

    public func search(query: String, limit: Int?) async throws -> [BaseItemDto] {
        do {
            // Search for songs by default
            let tracks = try await client.searchForTracks(query: query, limit: limit ?? 20)
            return tracks.toBaseItemDtos()
        } catch let error as YTMusicError {
            throw mapError(error)
        }
    }

    public func getArtistDetails(artistID: String) async throws -> BaseItemDto {
        do {
            let artist = try await client.fetchArtist(id: artistID)
            return artist.toBaseItemDto()
        } catch let error as YTMusicError {
            throw mapError(error)
        }
    }

    public func getAlbumDetails(albumID: String) async throws -> BaseItemDto {
        do {
            let (album, _) = try await client.fetchAlbum(id: albumID)
            return album.toBaseItemDto()
        } catch let error as YTMusicError {
            throw mapError(error)
        }
    }

    // MARK: - Extended API (YouTube Music Specific)

    /// Get user's liked songs playlist
    public func getLikedSongs() async throws -> [BaseItemDto] {
        guard isAuthenticated else {
            throw MusicProviderError.notAuthenticated
        }

        do {
            let tracks = try await client.fetchLikedSongs()
            return tracks.toBaseItemDtos()
        } catch let error as YTMusicError {
            throw mapError(error)
        }
    }

    /// Get user's playlists
    public func getPlaylists(limit: Int = 25) async throws -> [BaseItemDto] {
        guard isAuthenticated else {
            throw MusicProviderError.notAuthenticated
        }

        do {
            let playlists = try await client.fetchLibraryPlaylists(limit: limit)
            return playlists.toBaseItemDtos()
        } catch let error as YTMusicError {
            throw mapError(error)
        }
    }

    /// Search specifically for artists
    public func searchArtists(query: String, limit: Int = 20) async throws -> [BaseItemDto] {
        do {
            let artists = try await client.searchForArtists(query: query, limit: limit)
            return artists.toBaseItemDtos()
        } catch let error as YTMusicError {
            throw mapError(error)
        }
    }

    /// Search specifically for albums
    public func searchAlbums(query: String, limit: Int = 20) async throws -> [BaseItemDto] {
        do {
            let albums = try await client.searchForAlbums(query: query, limit: limit)
            return albums.toBaseItemDtos()
        } catch let error as YTMusicError {
            throw mapError(error)
        }
    }

    // MARK: - Private Helpers

    /// Map YTMusicError to MusicProviderError
    private func mapError(_ error: YTMusicError) -> MusicProviderError {
        switch error {
        case .notAuthenticated, .authTokenRefreshFailed, .authDenied:
            return .notAuthenticated
        case .notFound:
            return .notFound
        case .timeout, .noConnection:
            return .networkError(underlying: error)
        default:
            return .providerError(message: error.localizedDescription)
        }
    }
}

// MARK: - Factory Registration

extension Container {

    /// YouTube Music provider as a singleton
    var youTubeMusicProvider: Factory<YouTubeMusicProvider> {
        self { YouTubeMusicProvider() }.singleton
    }
}
