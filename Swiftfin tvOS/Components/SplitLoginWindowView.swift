//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct SplitLoginWindowView<Leading: View, Trailing: View>: View {

    // MARK: - Loading State

    private let isLoading: Bool

    // MARK: - Content Variables

    private let leadingContentView: Leading
    private let trailingContentView: Trailing

    // MARK: - Background Variable

    private let backgroundImageSource: ImageSource?

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: 60) {
            VStack(alignment: .leading, spacing: 24) {
                leadingContentView
            }
            .frame(minWidth: 500, maxWidth: 600, minHeight: 300)
            .padding(.vertical, 60)

            Divider()

            VStack(alignment: .leading, spacing: 24) {
                trailingContentView
            }
            .frame(minWidth: 450, maxWidth: .infinity, minHeight: 300)
            .padding(.vertical, 60)
        }
        .padding(.horizontal, 80)
        .navigationBarBranding(isLoading: isLoading)
        .background {
            if let backgroundImageSource {
                ZStack {
                    ImageView(backgroundImageSource)
                        .aspectRatio(contentMode: .fill)
                        .id(backgroundImageSource)
                        .transition(.opacity)
                        .animation(.linear, value: backgroundImageSource)

                    Color.black
                        .opacity(0.9)
                }
                .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
        }
    }
}

extension SplitLoginWindowView {

    init(
        isLoading: Bool = false,
        backgroundImageSource: ImageSource? = nil,
        @ViewBuilder leadingContentView: @escaping () -> Leading,
        @ViewBuilder trailingContentView: @escaping () -> Trailing
    ) {
        self.backgroundImageSource = backgroundImageSource
        self.isLoading = isLoading
        self.leadingContentView = leadingContentView()
        self.trailingContentView = trailingContentView()
    }
}
