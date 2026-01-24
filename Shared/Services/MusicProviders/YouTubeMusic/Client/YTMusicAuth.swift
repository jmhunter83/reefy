//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import KeychainSwift
import Logging

/// Handles OAuth authentication for YouTube Music via Reefy Auth Bridge
///
/// Since tvOS has no browser, we use a Cloudflare-hosted OAuth bridge:
/// 1. App requests a code from our bridge
/// 2. User sees a code on screen (e.g., "ABC123")
/// 3. User visits reefy-auth.pages.dev on their phone
/// 4. User enters code and completes Google OAuth on phone
/// 5. App polls our bridge until tokens are ready
///
/// Reference: https://github.com/jmhunter/reefy-auth
final class YTMusicAuth: ObservableObject {

    // MARK: - Types

    /// Current state of the authentication flow
    enum AuthState: Equatable {
        case idle
        case awaitingUserAction(BridgeCodeResponse)
        case polling
        case authenticated
        case failed(YTMusicError)
    }

    /// Response from the bridge code request
    struct BridgeCodeResponse: Equatable, Codable {
        let code: String
        let verificationUrl: String
        let expiresIn: Int

        enum CodingKeys: String, CodingKey {
            case code
            case verificationUrl = "verificationUrl"
            case expiresIn
        }
    }

    /// Response when polling the bridge
    struct BridgePollResponse: Codable {
        let status: String // "pending", "completed", "expired", "not_found"
        let accessToken: String?
        let refreshToken: String?
        let expiresIn: Int?
    }

    /// OAuth token response
    struct TokenResponse: Codable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int
        let tokenType: String
        let scope: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case tokenType = "token_type"
            case scope
        }
    }

    // MARK: - Properties

    @Published private(set) var state: AuthState = .idle

    private let keychain: KeychainSwift
    private let logger = Logger.swiftfin()
    private var pollingTask: Task<Void, Never>?

    /// Current access token (nil if not authenticated)
    var accessToken: String? {
        keychain.get(Keys.accessToken)
    }

    /// Whether the user is currently authenticated
    var isAuthenticated: Bool {
        accessToken != nil
    }

    /// Token expiration date
    private var tokenExpirationDate: Date? {
        guard let expirationString = keychain.get(Keys.tokenExpiration),
              let expiration = Double(expirationString)
        else {
            return nil
        }
        return Date(timeIntervalSince1970: expiration)
    }

    /// Whether the current token has expired
    var isTokenExpired: Bool {
        guard let expirationDate = tokenExpirationDate else { return true }
        return Date() >= expirationDate
    }

    // MARK: - OAuth Configuration

    /// Reefy Auth Bridge endpoints - handles the web OAuth flow for tvOS
    private enum Bridge {
        static let baseURL = URL(string: "https://reefy-auth.pages.dev")!
        static let initiateURL = baseURL.appendingPathComponent("api/initiate")

        static func pollURL(code: String) -> URL {
            baseURL.appendingPathComponent("api/poll/\(code)")
        }
    }

    /// Direct Google endpoints - only used for token refresh
    private enum Google {
        // Note: Client credentials are stored on the bridge server, not in the app.
        // The bridge handles the full OAuth exchange securely.
        // We only need the token URL for refreshing tokens with the refresh_token.
        static let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!

        // These are still needed for token refresh requests
        // In production, consider fetching these from a secure config endpoint
        static let clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"
        static let clientSecret = "YOUR_CLIENT_SECRET"
    }

    // MARK: - Keychain Keys

    private enum Keys {
        static let accessToken = "ytmusic_access_token"
        static let refreshToken = "ytmusic_refresh_token"
        static let tokenExpiration = "ytmusic_token_expiration"
    }

    // MARK: - Initialization

    init(keychain: KeychainSwift = KeychainSwift()) {
        self.keychain = keychain
        keychain.accessGroup = nil // Use app's default keychain

        // Check if we have stored credentials
        if accessToken != nil && !isTokenExpired {
            state = .authenticated
        }
    }

    // MARK: - Public Methods

    /// Start the authentication process via Reefy Auth Bridge
    ///
    /// This will request a code from our bridge and update `state` to `.awaitingUserAction`
    /// with the code and verification URL to show the user.
    @MainActor
    func startAuthentication() async throws {
        state = .idle

        let bridgeCode = try await requestBridgeCode()
        state = .awaitingUserAction(bridgeCode)
    }

    /// Begin polling for authorization after user sees the code
    ///
    /// Call this after presenting the code to the user.
    /// The flow will automatically complete when the user completes OAuth on their phone.
    @MainActor
    func startPolling() async {
        guard case let .awaitingUserAction(bridgeCode) = state else {
            logger.warning("startPolling called without bridge code")
            return
        }

        state = .polling
        pollingTask?.cancel()

        pollingTask = Task { [weak self] in
            await self?.pollBridgeForToken(code: bridgeCode.code, expiresIn: bridgeCode.expiresIn)
        }
    }

    /// Cancel the current authentication flow
    @MainActor
    func cancelAuthentication() {
        pollingTask?.cancel()
        pollingTask = nil
        state = .idle
    }

    /// Refresh the access token using the stored refresh token
    @MainActor
    func refreshAccessToken() async throws {
        guard let refreshToken = keychain.get(Keys.refreshToken) else {
            throw YTMusicError.notAuthenticated
        }

        let token = try await requestTokenRefresh(refreshToken: refreshToken)
        storeToken(token)
        state = .authenticated
    }

    /// Sign out and clear stored credentials
    @MainActor
    func signOut() {
        pollingTask?.cancel()
        pollingTask = nil

        keychain.delete(Keys.accessToken)
        keychain.delete(Keys.refreshToken)
        keychain.delete(Keys.tokenExpiration)

        state = .idle
    }

    /// Get a valid access token, refreshing if necessary
    func getValidAccessToken() async throws -> String {
        if let token = accessToken, !isTokenExpired {
            return token
        }

        // Try to refresh
        try await refreshAccessToken()

        guard let token = accessToken else {
            throw YTMusicError.notAuthenticated
        }

        return token
    }

    // MARK: - Private Methods

    /// Request a code from the Reefy Auth Bridge
    private func requestBridgeCode() async throws -> BridgeCodeResponse {
        var request = URLRequest(url: Bridge.initiateURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw YTMusicError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw YTMusicError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(BridgeCodeResponse.self, from: data)
    }

    /// Poll the bridge for tokens until user completes OAuth or code expires
    private func pollBridgeForToken(code: String, expiresIn: Int) async {
        let deadline = Date().addingTimeInterval(TimeInterval(expiresIn))
        let interval: TimeInterval = 3 // Poll every 3 seconds

        while Date() < deadline {
            guard !Task.isCancelled else {
                await MainActor.run { state = .idle }
                return
            }

            // Wait before polling
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

            do {
                let pollResponse = try await pollBridge(code: code)

                switch pollResponse.status {
                case "completed":
                    // Tokens are ready
                    guard let accessToken = pollResponse.accessToken else {
                        logger.error("Bridge returned completed but no access token")
                        await MainActor.run { state = .failed(.unknown(message: "No access token in response")) }
                        return
                    }

                    let token = TokenResponse(
                        accessToken: accessToken,
                        refreshToken: pollResponse.refreshToken,
                        expiresIn: pollResponse.expiresIn ?? 3600,
                        tokenType: "Bearer",
                        scope: nil
                    )

                    await MainActor.run {
                        storeToken(token)
                        state = .authenticated
                    }
                    return

                case "expired", "not_found":
                    await MainActor.run { state = .failed(.authCodeExpired) }
                    return

                case "pending":
                    // Continue polling
                    continue

                default:
                    logger.warning("Unknown bridge status: \(pollResponse.status)")
                    continue
                }
            } catch {
                logger.error("Error polling bridge: \(error)")
                continue
            }
        }

        // Deadline reached
        await MainActor.run { state = .failed(.authCodeExpired) }
    }

    /// Poll the bridge for token status
    private func pollBridge(code: String) async throws -> BridgePollResponse {
        var request = URLRequest(url: Bridge.pollURL(code: code))
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw YTMusicError.invalidResponse
        }

        // 404 means code not found
        if httpResponse.statusCode == 404 {
            return BridgePollResponse(status: "not_found", accessToken: nil, refreshToken: nil, expiresIn: nil)
        }

        if httpResponse.statusCode != 200 {
            throw YTMusicError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }

        return try JSONDecoder().decode(BridgePollResponse.self, from: data)
    }

    /// Refresh access token using refresh token
    ///
    /// Note: Token refresh still goes directly to Google since we have the refresh_token.
    /// Only the initial OAuth flow goes through our bridge.
    private func requestTokenRefresh(refreshToken: String) async throws -> TokenResponse {
        var request = URLRequest(url: Google.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "client_id": Google.clientID,
            "client_secret": Google.clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
        ]
        request.httpBody = body.urlEncodedString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw YTMusicError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw YTMusicError.authTokenRefreshFailed
        }

        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    /// Store token response in keychain
    private func storeToken(_ token: TokenResponse) {
        keychain.set(token.accessToken, forKey: Keys.accessToken)

        if let refreshToken = token.refreshToken {
            keychain.set(refreshToken, forKey: Keys.refreshToken)
        }

        let expirationDate = Date().addingTimeInterval(TimeInterval(token.expiresIn))
        keychain.set(String(expirationDate.timeIntervalSince1970), forKey: Keys.tokenExpiration)
    }
}

// MARK: - Dictionary Extension for URL Encoding

private extension Dictionary where Key == String, Value == String {
    var urlEncodedString: String {
        map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
    }
}
