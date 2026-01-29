//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import SwiftUI

@MainActor
class MusicPlaylistQueue: ViewModel, MediaPlayerQueue {

    weak var manager: MediaPlayerManager? {
        didSet {
            cancellables = []
            guard let manager else { return }

            // Observe playback item changes
            manager.$playbackItem
                .sink { [weak self] newItem in
                    self?.updateAdjacentItems(for: newItem?.baseItem)
                }
                .store(in: &cancellables)

            // Observe shuffle changes
            manager.$shuffleEnabled
                .dropFirst()
                .sink { [weak self] _ in
                    self?.rebuildQueue()
                }
                .store(in: &cancellables)

            // Observe repeat changes
            manager.$repeatMode
                .dropFirst()
                .sink { [weak self] _ in
                    self?.rebuildQueue()
                }
                .store(in: &cancellables)
        }
    }

    let displayTitle: String
    let id: String = "MusicPlaylistQueue"

    @Published
    var nextItem: MediaPlayerItemProvider? = nil
    @Published
    var previousItem: MediaPlayerItemProvider? = nil

    @Published
    var hasNextItem: Bool = false
    @Published
    var hasPreviousItem: Bool = false

    lazy var hasNextItemPublisher: Published<Bool>.Publisher = $hasNextItem
    lazy var hasPreviousItemPublisher: Published<Bool>.Publisher = $hasPreviousItem
    lazy var nextItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $nextItem
    lazy var previousItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $previousItem

    private let originalItems: [BaseItemDto]
    private var currentItems: [BaseItemDto] = []

    init(items: [BaseItemDto], title: String = L10n.music) {
        self.originalItems = items
        self.displayTitle = title
        super.init()

        rebuildQueue()
    }

    var videoPlayerBody: some PlatformView {
        InlinePlatformView {
            EmptyView()
        } tvOSView: {
            EmptyView()
        }
    }

    private func rebuildQueue() {
        guard let manager else {
            currentItems = originalItems
            return
        }

        if manager.shuffleEnabled {
            // Shuffle logic: Keep current item as first or just shuffle all
            let currentItem = manager.item
            var itemsToShuffle = originalItems

            if let index = itemsToShuffle.firstIndex(where: { $0.id == currentItem.id }) {
                itemsToShuffle.remove(at: index)
                currentItems = [currentItem] + itemsToShuffle.shuffled()
            } else {
                currentItems = originalItems.shuffled()
            }
        } else {
            currentItems = originalItems
        }

        updateAdjacentItems(for: manager.item)
    }

    private func updateAdjacentItems(for item: BaseItemDto?) {
        guard let item, let index = currentItems.firstIndex(where: { $0.id == item.id }) else {
            nextItem = nil
            previousItem = nil
            hasNextItem = false
            hasPreviousItem = false
            return
        }

        let repeatMode = manager?.repeatMode ?? .off

        // Resolve Next Item
        var nextItemDto: BaseItemDto?
        if index + 1 < currentItems.count {
            nextItemDto = currentItems[index + 1]
        } else if repeatMode == .all {
            nextItemDto = currentItems.first
        } else if repeatMode == .one {
            nextItemDto = item
        }

        // Resolve Previous Item
        var previousItemDto: BaseItemDto?
        if index - 1 >= 0 {
            previousItemDto = currentItems[index - 1]
        } else if repeatMode == .all {
            previousItemDto = currentItems.last
        } else if repeatMode == .one {
            previousItemDto = item
        }

        self.nextItem = nextItemDto.map { dto in
            MediaPlayerItemProvider(item: dto) { item in
                try await MediaPlayerItem.build(for: item) {
                    $0.userData?.playbackPositionTicks = .zero
                }
            }
        }

        self.previousItem = previousItemDto.map { dto in
            MediaPlayerItemProvider(item: dto) { item in
                try await MediaPlayerItem.build(for: item) {
                    $0.userData?.playbackPositionTicks = .zero
                }
            }
        }

        self.hasNextItem = nextItem != nil
        self.hasPreviousItem = previousItem != nil
    }
}
