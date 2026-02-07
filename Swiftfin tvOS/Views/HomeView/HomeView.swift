//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

struct HomeView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = HomeViewModel()

    @Default(.Customization.Home.showRecentlyAdded)
    private var showRecentlyAdded

    private var hasResumeItems: Bool {
        viewModel.resumeItems.isNotEmpty
    }

    private var hasNextUpItems: Bool {
        viewModel.nextUpViewModel.elements.isNotEmpty
    }

    private var hasRecentlyAddedItems: Bool {
        showRecentlyAdded && viewModel.recentlyAddedViewModel.elements.isNotEmpty
    }

    private var hasLibraryItems: Bool {
        viewModel.libraries.contains(where: \.elements.isNotEmpty)
    }

    private var hasVisibleContent: Bool {
        hasResumeItems || hasNextUpItems || hasRecentlyAddedItems || hasLibraryItems
    }

    private var isAnySectionRefreshing: Bool {
        viewModel.nextUpViewModel.state == .refreshing ||
            viewModel.recentlyAddedViewModel.state == .refreshing ||
            viewModel.libraries.contains(where: { $0.state == .refreshing })
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text(L10n.noResults)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height - 75)
        .edgePadding(.horizontal)
    }

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                if hasVisibleContent {
                    if hasResumeItems {
                        CinematicResumeView(viewModel: viewModel)

                        NextUpView(viewModel: viewModel.nextUpViewModel)

                        if showRecentlyAdded {
                            RecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)
                        }
                    } else {
                        if hasRecentlyAddedItems {
                            CinematicRecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)
                        }

                        NextUpView(viewModel: viewModel.nextUpViewModel)
                            .safeAreaPadding(.top, hasRecentlyAddedItems ? 150 : 0)
                    }

                    ForEach(viewModel.libraries) { viewModel in
                        LatestInLibraryView(viewModel: viewModel)
                    }
                } else if isAnySectionRefreshing {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height - 75)
                } else {
                    emptyStateView
                }
            }
        }
    }

    var body: some View {
        ZStack {
            Color.clear

            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .refreshable {
            viewModel.send(.refresh)
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .ignoresSafeArea()
        .sinceLastDisappear { interval in
            if interval > 60 || viewModel.notificationsReceived.contains(.itemMetadataDidChange) {
                viewModel.send(.backgroundRefresh)
                viewModel.notificationsReceived.remove(.itemMetadataDidChange)
            }
        }
        .onReceive(Notifications[.didRequestGlobalRefresh].publisher) { _ in
            viewModel.send(.backgroundRefresh)
        }
    }
}
