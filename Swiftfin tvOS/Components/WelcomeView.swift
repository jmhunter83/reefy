//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct WelcomeView: View {

    let changelog: ChangelogEntry
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            // Title
            Text("Welcome to Reefy \(changelog.version)")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Changelog items
            VStack(alignment: .leading, spacing: 30) {
                ForEach(changelog.items.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 20) {
                        Image(systemName: changelog.items[index].icon)
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                            .frame(width: 60)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(changelog.items[index].title)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(changelog.items[index].description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: 800)

            Spacer()

            // Dismiss button
            Button {
                onDismiss()
            } label: {
                Text("Continue")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(width: 300, height: 60)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
