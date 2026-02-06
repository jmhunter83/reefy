//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct LibrarySortView<Element: Poster & Identifiable>: View {

    @Default(.accentColor)
    private var accentColor

    @Environment(\.dismiss)
    private var dismiss

    @ObservedObject
    var viewModel: PagingLibraryViewModel<Element>

    private var currentSortBy: ItemSortBy {
        viewModel.filterViewModel?.currentFilters.sortBy.first ?? .sortName
    }

    private var currentSortOrder: ItemSortOrder {
        viewModel.filterViewModel?.currentFilters.sortOrder.first ?? .ascending
    }

    private func updateSortBy(_ sortBy: ItemSortBy) {
        viewModel.filterViewModel?.send(.update(.sortBy, [sortBy.asAnyItemFilter]))
    }

    private func updateSortOrder(_ sortOrder: ItemSortOrder) {
        viewModel.filterViewModel?.send(.update(.sortOrder, [sortOrder.asAnyItemFilter]))
    }

    private func resetSort() {
        viewModel.filterViewModel?.send(.reset(.sortBy))
        viewModel.filterViewModel?.send(.reset(.sortOrder))
    }

    var body: some View {
        NavigationStack {
            List {
                Section(L10n.sort) {
                    ForEach(ItemSortBy.supportedCases, id: \.self) { sortOption in
                        Button {
                            updateSortBy(sortOption)
                        } label: {
                            HStack {
                                Text(sortOption.displayTitle)
                                    .foregroundColor(.primary)

                                Spacer()

                                if currentSortBy == sortOption {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(accentColor)
                                }
                            }
                        }
                    }
                }

                Section(L10n.order) {
                    ForEach(ItemSortOrder.allCases, id: \.self) { order in
                        Button {
                            updateSortOrder(order)
                        } label: {
                            HStack {
                                Text(order.displayTitle)
                                    .foregroundColor(.primary)

                                Spacer()

                                if currentSortOrder == order {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(accentColor)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        resetSort()
                    } label: {
                        HStack {
                            Spacer()
                            Text(L10n.reset)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(L10n.sort)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.close) {
                        dismiss()
                    }
                }
            }
        }
    }
}
