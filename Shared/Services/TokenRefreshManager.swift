//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import Logging

actor TokenRefreshManager {
    private let logger = Logger.swiftfin()
    private var isRefreshing = false
    private var refreshTasks: [String: Task<UserSession?, Error>] = [:]

    /// Attempts to refresh a token using stored credentials
    func refreshToken(
        for userSession: UserSession,
        storedPassword: String
    ) async throws -> UserSession {
        let userId = userSession.user.id

        // Prevent multiple simultaneous refreshes for the same user
        if isRefreshing, let existingTask = refreshTasks[userId] {
            return try await existingTask.value
        }

        let task = Task<UserSession?, Error> {
            isRefreshing = true
            defer {
                isRefreshing = false
                refreshTasks[userId] = nil
            }

            logger.info("Refreshing token for user \(userSession.user.username)")

            do {
                // Attempt to re-authenticate with stored password
                let response = try await userSession.server.client.signIn(
                    username: userSession.user.username,
                    password: storedPassword
                )

                guard let newToken = response.accessToken,
                      let userData = response.user,
                      let newUserId = userData.id
                else {
                    throw TokenRefreshError.invalidResponse
                }

                // Create new session with refreshed token
                let newUser = try await userSession.user.getUserData(server: userSession.server)
                var updatedUser = userSession.user
                updatedUser.data = newUser

                updatedUser.accessToken = newToken

                let newSession = UserSession(
                    server: userSession.server,
                    user: updatedUser
                )

                logger.info("Successfully refreshed token for user \(userSession.user.username)")
                return newSession

            } catch {
                logger.warning("Failed to refresh token for user \(userSession.user.username): \(error.localizedDescription)")
                throw error
            }
        }

        refreshTasks[userId] = task

        guard let result = try await task.value else {
            throw TokenRefreshError.invalidResponse
        }
        return result
    }

    /// Stores encrypted password for token refresh
    func storePassword(_ password: String, for userId: String) {
        // TODO: Implement secure password storage
        // For now, store in Keychain with high protection level
        let keychain = Container.shared.keychainService()
        keychain.set(password, forKey: "\(userId)-refreshPassword", withAccess: .accessibleWhenUnlockedThisDeviceOnly)
    }

    /// Retrieves stored password for refresh
    func getStoredPassword(for userId: String) -> String? {
        let keychain = Container.shared.keychainService()
        return keychain.get("\(userId)-refreshPassword")
    }

    /// Clears stored refresh password
    func clearStoredPassword(for userId: String) {
        let keychain = Container.shared.keychainService()
        keychain.delete("\(userId)-refreshPassword")
    }

    enum TokenRefreshError: LocalizedError {
        case invalidResponse
        case networkError(Error)
        case authenticationFailed

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Server returned invalid response during token refresh"
            case let .networkError(error):
                return "Network error during token refresh: \(error.localizedDescription)"
            case .authenticationFailed:
                return "Authentication failed during token refresh"
            }
        }
    }
} </ content>
<parameter name = "filePath" >/ Users / jmhunter / Projects / Software_Projects / swiftfin / Shared / Services / TokenRefreshManager.swift
