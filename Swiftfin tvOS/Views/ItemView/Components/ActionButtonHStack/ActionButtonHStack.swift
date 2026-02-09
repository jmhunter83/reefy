//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ActionButtonHStack: View {

        private enum EventBannerStyle {
            case success
            case error

            var tintColor: Color {
                switch self {
                case .success:
                    return .green
                case .error:
                    return .red
                }
            }
        }

        private struct EventBanner: Equatable {
            let message: String
            let systemName: String
            let style: EventBannerStyle
        }

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        // MARK: - Observed, State, & Environment Objects

        @Router
        private var router

        @ObservedObject
        var viewModel: ItemViewModel

        @StateObject
        private var deleteViewModel: DeleteItemViewModel
        @StateObject
        private var metadataViewModel: RefreshMetadataViewModel

        // MARK: - Dialog States

        @State
        private var showConfirmationDialog = false
        @State
        private var eventBanner: EventBanner?
        @State
        private var eventBannerDismissTask: Task<Void, Never>?

        // MARK: - Error State

        @State
        private var error: Error?

        // MARK: - Can Delete Item

        private var canDelete: Bool {
            viewModel.userSession?.user.permissions.items.canDelete(item: viewModel.item) == true
        }

        // MARK: - Can Refresh Item

        private var canRefresh: Bool {
            viewModel.userSession?.user.permissions.items.canEditMetadata(item: viewModel.item) == true
        }

        // MARK: - Can Manage Subtitles

        private var canManageSubtitles: Bool {
            viewModel.userSession?.user.permissions.items.canManageSubtitles(item: viewModel.item) == true
        }

        // MARK: - Deletion or Refreshing is Enabled

        private var enableMenu: Bool {
            canDelete || canRefresh
        }

        // MARK: - Has Trailers

        private var hasTrailers: Bool {
            if enabledTrailers.contains(.local), viewModel.localTrailers.isNotEmpty {
                return true
            }

            if enabledTrailers.contains(.external), viewModel.item.remoteTrailers?.isNotEmpty == true {
                return true
            }

            return false
        }

        @ViewBuilder
        private var eventBannerView: some View {
            if let eventBanner {
                HStack(spacing: 10) {
                    Image(systemName: eventBanner.systemName)
                        .font(.caption.weight(.bold))

                    Text(eventBanner.message)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    eventBanner.style.tintColor.opacity(0.9),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }

        // MARK: - Initializer

        init(viewModel: ItemViewModel) {
            self.viewModel = viewModel
            self._deleteViewModel = StateObject(wrappedValue: .init(item: viewModel.item))
            self._metadataViewModel = StateObject(wrappedValue: .init(item: viewModel.item))
        }

        // MARK: - Body

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                eventBannerView

                HStack(alignment: .center, spacing: 30) {

                    // MARK: Toggle Played

                    if viewModel.item.canBePlayed {
                        let isCheckmarkSelected = viewModel.item.userData?.isPlayed == true

                        Button(L10n.played, systemImage: "checkmark") {
                            viewModel.send(.toggleIsPlayed)
                        }
                        .buttonStyle(.tintedMaterial(tint: Color.jellyfinPurple, foregroundColor: .primary))
                        .isSelected(isCheckmarkSelected)
                        .frame(width: 100, height: 100)
                    }

                    // MARK: Toggle Favorite

                    let isHeartSelected = viewModel.item.userData?.isFavorite == true

                    Button(L10n.favorited, systemImage: isHeartSelected ? "heart.fill" : "heart") {
                        viewModel.send(.toggleIsFavorite)
                    }
                    .buttonStyle(.tintedMaterial(tint: .pink, foregroundColor: .primary))
                    .isSelected(isHeartSelected)
                    .frame(width: 100, height: 100)

                    // MARK: Watch a Trailer

                    if hasTrailers {
                        TrailerMenu(
                            localTrailers: viewModel.localTrailers,
                            externalTrailers: viewModel.item.remoteTrailers ?? []
                        )
                        .buttonStyle(.tintedMaterial(tint: .pink, foregroundColor: .primary))
                        .frame(width: 100, height: 100)
                    }

                    // MARK: Advanced Options

                    if enableMenu {
                        Menu {
                            if canRefresh || canManageSubtitles {
                                Section(L10n.manage) {
                                    if canRefresh {
                                        Button(L10n.refreshMetadata, systemImage: "arrow.clockwise") {
                                            router.route(to: .itemMetadataRefresh(viewModel: metadataViewModel))
                                        }
                                    }

                                    if canManageSubtitles {
                                        Button(L10n.subtitles, systemImage: "textformat") {
                                            router.route(
                                                to: .searchSubtitle(
                                                    viewModel: .init(item: viewModel.item)
                                                )
                                            )
                                        }
                                    }
                                }
                            }

                            if canDelete {
                                Section {
                                    Button(L10n.delete, systemImage: "trash", role: .destructive) {
                                        showConfirmationDialog = true
                                    }
                                }
                            }
                        } label: {
                            Label(L10n.advanced, systemImage: "ellipsis")
                                .rotationEffect(.degrees(90))
                        }
                        .buttonStyle(.material)
                        .frame(width: 60, height: 100)
                    }
                }
                .frame(height: 100)
            }
            .labelStyle(.iconOnly)
            .font(.title3)
            .fontWeight(.semibold)
            .onReceive(viewModel.events) { event in
                switch event {
                case let .favoriteUpdated(isFavorite):
                    presentEventBanner(
                        message: isFavorite ? L10n.favorited : L10n.favorite,
                        systemName: isFavorite ? "heart.fill" : "heart.slash",
                        style: .success
                    )
                case .favoriteUpdateFailed:
                    presentEventBanner(
                        message: L10n.error,
                        systemName: "exclamationmark.triangle.fill",
                        style: .error
                    )
                case let .playedUpdated(isPlayed):
                    presentEventBanner(
                        message: L10n.played,
                        systemName: isPlayed ? "checkmark.circle.fill" : "checkmark.circle",
                        style: .success
                    )
                case .playedUpdateFailed:
                    presentEventBanner(
                        message: L10n.error,
                        systemName: "exclamationmark.triangle.fill",
                        style: .error
                    )
                }
            }
            .confirmationDialog(
                L10n.deleteItemConfirmationMessage,
                isPresented: $showConfirmationDialog,
                titleVisibility: .visible
            ) {
                Button(L10n.confirm, role: .destructive) {
                    deleteViewModel.send(.delete)
                }
                Button(L10n.cancel, role: .cancel) {}
            }
            .onReceive(deleteViewModel.events) { event in
                switch event {
                case let .error(eventError):
                    error = eventError
                case .deleted:
                    router.dismiss()
                }
            }
            .onDisappear {
                eventBannerDismissTask?.cancel()
                eventBannerDismissTask = nil
            }
            .errorMessage($error)
        }

        private func presentEventBanner(
            message: String,
            systemName: String,
            style: EventBannerStyle
        ) {
            eventBannerDismissTask?.cancel()

            withAnimation(.spring(duration: 0.3)) {
                eventBanner = EventBanner(
                    message: message,
                    systemName: systemName,
                    style: style
                )
            }

            eventBannerDismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    eventBanner = nil
                }
            }
        }
    }
}
