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
import Get
import JellyfinAPI
import OrderedCollections
import UIKit

// TODO: come up with a cleaner, more defined way for item update notifications

class ItemViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case backgroundRefresh
        case error(ErrorMessage)
        case refresh
        case replace(BaseItemDto)
        case toggleIsFavorite
        case toggleIsPlayed
        case selectMediaSource(MediaSourceInfo)
    }

    // MARK: BackgroundState

    enum BackgroundState: Hashable {
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(ErrorMessage)
        case initial
        case refreshing
    }

    // TODO: create value on `BaseItemDto` whether an item
    //       only has children as playable items
    @Published
    private(set) var item: BaseItemDto {
        willSet {
            if item.isPlayable {
                playButtonItem = newValue
            }
        }
    }

    @Published
    var playButtonItem: BaseItemDto? {
        willSet {
            if let newValue {
                selectedMediaSource = newValue.mediaSources?.first
            }
        }
    }

    @Published
    private(set) var selectedMediaSource: MediaSourceInfo?
    @Published
    private(set) var similarItems: [BaseItemDto] = []
    @Published
    private(set) var specialFeatures: [BaseItemDto] = []
    @Published
    private(set) var localTrailers: [BaseItemDto] = []
    @Published
    private(set) var additionalParts: [BaseItemDto] = []

    @Published
    var backgroundStates: Set<BackgroundState> = []
    @Published
    var state: State = .initial

    private var itemID: String {
        get throws {
            guard let id = item.id else {
                logger.error("Item ID is nil")
                throw ErrorMessage(L10n.unknownError)
            }
            return id
        }
    }

    // tasks

    private var toggleIsFavoriteTask: AnyCancellable?
    private var toggleIsPlayedTask: AnyCancellable?
    private var refreshTask: AnyCancellable?

    // Synchronization for item updates to prevent race conditions
    private let itemUpdateQueue = DispatchQueue(label: "com.jellyfin.reefy.itemViewModel.itemUpdate")
    private var itemVersion: UInt64 = 0

    // MARK: init

    init(item: BaseItemDto) {
        self.item = item
        super.init()

        Notifications[.itemShouldRefreshMetadata]
            .filtered { [weak self] itemID in itemID == self?.item.id }
            .sink { [weak self] _ in
                Task {
                    await self?.send(.backgroundRefresh)
                }
            }
            .store(in: &cancellables)

        Notifications[.itemMetadataDidChange]
            .filtered { [weak self] newItem in newItem.id == self?.item.id }
            .sink { [weak self] newItem in
                Task {
                    await self?.send(.replace(newItem))
                }
            }
            .store(in: &cancellables)
    }

    convenience init(episode: BaseItemDto) {
        let shellSeriesItem = BaseItemDto(id: episode.seriesID, name: episode.seriesName)
        self.init(item: shellSeriesItem)
    }

    // MARK: - Item Update Synchronization

    /// Safely updates the item with version checking to prevent race conditions
    private func updateItem(_ newItem: BaseItemDto, version: UInt64) {
        itemUpdateQueue.async { [weak self] in
            guard let self else { return }

            // Only update if this version is newer than what we have
            guard version > self.itemVersion else { return }
            self.itemVersion = version

            Task { @MainActor [weak self] in
                self?.item = newItem
            }
        }
    }

    // MARK: respond

    func respond(to action: Action) -> State {
        switch action {
        case .backgroundRefresh:

            backgroundStates.insert(.refresh)

            Task { [weak self] in
                guard let self else { return }
                do {
                    async let fullItem = getFullItem()
                    async let similarItems = getSimilarItems()
                    async let specialFeatures = getSpecialFeatures()
                    async let localTrailers = getLocalTrailers()

                    let results = try await (
                        fullItem: fullItem,
                        similarItems: similarItems,
                        specialFeatures: specialFeatures,
                        localTrailers: localTrailers
                    )

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.backgroundStates.remove(.refresh)

                        // Generate version for this update
                        let updateVersion = self.itemVersion + 1

                        // Use versioned update instead of direct assignment
                        if results.fullItem.id != self.item.id || results.fullItem != self.item {
                            self.updateItem(results.fullItem, version: updateVersion)
                        }

                        if !results.similarItems.elementsEqual(self.similarItems, by: { $0.id == $1.id }) {
                            self.similarItems = results.similarItems
                        }

                        if !results.specialFeatures.elementsEqual(self.specialFeatures, by: { $0.id == $1.id }) {
                            self.specialFeatures = results.specialFeatures
                        }

                        if !results.localTrailers.elementsEqual(self.localTrailers, by: { $0.id == $1.id }) {
                            self.localTrailers = results.localTrailers
                        }
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.backgroundStates.remove(.refresh)
                        self.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .store(in: &cancellables)

            return state
        case let .error(error):
            return .error(error)
        case .refresh:

            refreshTask?.cancel()

            refreshTask = Task { [weak self] in
                guard let self else { return }
                do {
                    async let fullItem = getFullItem()
                    async let similarItems = getSimilarItems()
                    async let specialFeatures = getSpecialFeatures()
                    async let localTrailers = getLocalTrailers()
                    async let additionalParts = getAdditionalParts()

                    let results = try await (
                        fullItem: fullItem,
                        similarItems: similarItems,
                        specialFeatures: specialFeatures,
                        localTrailers: localTrailers,
                        additionalParts: additionalParts
                    )

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        // Generate version for this update
                        let updateVersion = self.itemVersion + 1

                        // Use versioned update
                        self.updateItem(results.fullItem, version: updateVersion)

                        // Other properties can be updated directly
                        self.similarItems = results.similarItems
                        self.specialFeatures = results.specialFeatures
                        self.localTrailers = results.localTrailers
                        self.additionalParts = results.additionalParts

                        self.state = .content
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .refreshing
        case let .replace(newItem):

            // Generate highest priority version (external updates are authoritative)
            let updateVersion = itemVersion + 100

            backgroundStates.insert(.refresh)

            Task { [weak self] in
                guard let self else { return }
                await MainActor.run {
                    self.backgroundStates.remove(.refresh)
                    self.updateItem(newItem, version: updateVersion)
                }
            }
            .store(in: &cancellables)

            return state
        case .toggleIsFavorite:

            toggleIsFavoriteTask?.cancel()

            toggleIsFavoriteTask = Task {

                let beforeIsFavorite = item.userData?.isFavorite ?? false

                await MainActor.run {
                    item.userData?.isFavorite?.toggle()
                }

                do {
                    try await setIsFavorite(!beforeIsFavorite)
                } catch {
                    await MainActor.run {
                        item.userData?.isFavorite = beforeIsFavorite
                        // emit event that toggle unsuccessful
                    }
                }
            }
            .asAnyCancellable()

            return state
        case .toggleIsPlayed:

            toggleIsPlayedTask?.cancel()

            toggleIsPlayedTask = Task {

                let beforeIsPlayed = item.userData?.isPlayed ?? false

                await MainActor.run {
                    item.userData?.isPlayed?.toggle()
                }

                do {
                    try await setIsPlayed(!beforeIsPlayed)
                } catch {
                    await MainActor.run {
                        item.userData?.isPlayed = beforeIsPlayed
                        // emit event that toggle unsuccessful
                    }
                }
            }
            .asAnyCancellable()

            return state
        case let .selectMediaSource(newSource):

            selectedMediaSource = newSource

            return state
        }
    }

    private func getFullItem() async throws -> BaseItemDto {
        let session = try requireSession()
        return try await item.getFullItem(userSession: session)
    }

    private func getSimilarItems() async -> [BaseItemDto] {
        guard let itemID = item.id else { return [] }
        guard let userSession = currentSession else { return [] }

        var parameters = Paths.GetSimilarItemsParameters()
        parameters.fields = .MinimumFields
        parameters.limit = 20
        parameters.userID = userSession.user.id

        let request = Paths.getSimilarItems(
            itemID: itemID,
            parameters: parameters
        )

        do {
            let response = try await userSession.client.send(request)
            return response.value.items ?? []
        } catch {
            logger.warning("Failed to fetch similar items for \(item.id): \(error.localizedDescription)")
            return []
        }
    }

    private func getSpecialFeatures() async -> [BaseItemDto] {
        guard let itemID = item.id else { return [] }
        guard let userSession = currentSession else { return [] }

        let request = Paths.getSpecialFeatures(
            itemID: itemID,
            userID: userSession.user.id
        )

        do {
            let response = try await userSession.client.send(request)
            return (response.value ?? [])
                .filter { $0.extraType?.isVideo ?? false }
        } catch {
            logger.warning("Failed to fetch special features for \(item.id): \(error.localizedDescription)")
            return []
        }
    }

    private func getLocalTrailers() async throws -> [BaseItemDto] {
        guard let userSession = currentSession else { return [] }

        let itemId = try itemID
        let request = try Paths.getLocalTrailers(itemID: itemId, userID: userSession.user.id)

        do {
            let response = try await userSession.client.send(request)
            return response.value ?? []
        } catch {
            logger.warning("Failed to fetch local trailers for \(itemId): \(error.localizedDescription)")
            return []
        }
    }

    private func getAdditionalParts() async throws -> [BaseItemDto] {
        guard let partCount = item.partCount,
              partCount > 1,
              let itemID = item.id else { return [] }
        guard let userSession = currentSession else { return [] }

        let request = Paths.getAdditionalPart(itemID: itemID)

        do {
            let response = try await userSession.client.send(request)
            return response.value.items ?? []
        } catch {
            logger.warning("Failed to fetch additional parts for \(itemID): \(error.localizedDescription)")
            return []
        }
    }

    private func setIsPlayed(_ isPlayed: Bool) async throws {

        guard let itemID = item.id else { return }
        guard let userSession = currentSession else { return }

        let request: Request<UserItemDataDto>

        if isPlayed {
            request = Paths.markPlayedItem(
                itemID: itemID,
                userID: userSession.user.id
            )
        } else {
            request = Paths.markUnplayedItem(
                itemID: itemID,
                userID: userSession.user.id
            )
        }

        _ = try await userSession.client.send(request)
        Notifications[.itemShouldRefreshMetadata].post(itemID)
    }

    private func setIsFavorite(_ isFavorite: Bool) async throws {

        guard let itemID = item.id else { return }
        guard let userSession = currentSession else { return }

        let request: Request<UserItemDataDto>

        if isFavorite {
            request = Paths.markFavoriteItem(
                itemID: itemID,
                userID: userSession.user.id
            )
        } else {
            request = Paths.unmarkFavoriteItem(
                itemID: itemID,
                userID: userSession.user.id
            )
        }

        _ = try await userSession.client.send(request)
        Notifications[.itemShouldRefreshMetadata].post(itemID)
    }
}
