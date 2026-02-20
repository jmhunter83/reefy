//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A reusable container that handles common loading, error, and empty states
/// for views backed by ViewModels with standard State enums.
struct StateContainer<Content: View, EmptyContent: View>: View {

    enum ViewState {
        case loading
        case content
        case error(Error)
        case empty
    }

    let state: ViewState
    @ViewBuilder
    let content: () -> Content
    @ViewBuilder
    let emptyContent: () -> EmptyContent

    var body: some View {
        ZStack {
            Color.clear

            switch state {
            case .loading:
                ProgressView()
            case .content:
                content()
            case let .error(error):
                ErrorView(error: error)
            case .empty:
                emptyContent()
            }
        }
    }
}

// MARK: - Convenience initializer with default empty view

extension StateContainer where EmptyContent == EmptyStateView {

    init(
        state: ViewState,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.state = state
        self.content = content
        self.emptyContent = { EmptyStateView() }
    }

    init(
        state: ViewState,
        emptyMessage: String,
        emptySystemImage: String = "tray",
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.state = state
        self.content = content
        self.emptyContent = {
            EmptyStateView(
                message: emptyMessage,
                systemImage: emptySystemImage
            )
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {

    let message: String
    let systemImage: String
    let action: (() -> Void)?
    let actionLabel: String?

    init(
        message: String = L10n.noResults,
        systemImage: String = "tray",
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.message = message
        self.systemImage = systemImage
        self.action = action
        self.actionLabel = actionLabel
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            Text(message)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let action, let actionLabel {
                Button(actionLabel, action: action)
                    .buttonStyle(.primary)
            }
        }
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusSection()
        .edgePadding()
    }
}
