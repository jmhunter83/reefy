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
import OrderedCollections

final class CollectionItemViewModel: ItemViewModel {

    @ObservedPublisher
    var sections: OrderedDictionary<BaseItemKind, ItemLibraryViewModel>

    private let itemCollection: ItemTypeCollection

    override init(item: BaseItemDto) {
        // Determine which item types to fetch based on parent type
        let itemTypes: [BaseItemKind]

        switch item.type {
        case .musicAlbum:
            // Albums only show audio tracks
            itemTypes = [.audio]
        case .musicArtist:
            // Artists show albums and audio tracks
            itemTypes = [.musicAlbum, .audio]
        default:
            // BoxSets, Persons, etc. - show supported media types + episodes + people
            itemTypes = BaseItemKind.supportedCases
                .appending(.episode)
                .appending(.person)
        }

        self.itemCollection = ItemTypeCollection(
            parent: item,
            itemTypes: itemTypes
        )
        self._sections = ObservedPublisher(
            wrappedValue: [:],
            observing: itemCollection.$elements
        )

        super.init(item: item)
    }

    // MARK: - Override Response

    override func respond(to action: ItemViewModel.Action) -> ItemViewModel.State {

        switch action {
        case .refresh, .backgroundRefresh:
            itemCollection.send(.refresh)
        default: ()
        }

        return super.respond(to: action)
    }

    // TODO: possibly multiple items, for image source fallbacks
    func randomItem() -> BaseItemDto? {
        // Try to exclude episodes if possible

        if itemCollection.elements.elements.count == 1 {
            return itemCollection.elements.elements.first?.value.elements.first
        }

        return itemCollection.elements
            .elements
            .shuffled()
            .filter { $0.key != .episode }
            .randomElement()?
            .value
            .elements
            .randomElement()
    }

    var allTracks: [BaseItemDto] {
        sections[.audio]?.elements ?? []
    }
}
