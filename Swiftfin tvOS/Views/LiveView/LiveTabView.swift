//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LiveTabView: View {

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "tv")
                .font(.system(size: 100))
                .foregroundColor(.secondary)

            Text(L10n.liveTV)
                .font(.title)
                .fontWeight(.bold)

            Text("Coming Soon")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
