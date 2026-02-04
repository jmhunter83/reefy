//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import PulseUI
import SwiftUI

/// A wrapper around Pulse's ConsoleView that adds a warning banner
/// about the filters crash bug in Pulse v5.1.4 on tvOS.
///
/// Issue: Navigating to "Message Filters" or "Network Filters" crashes
/// because ConsoleFiltersView can't access required @EnvironmentObject
/// due to a nested NavigationView breaking the environment chain.
///
/// This wrapper preserves all functionality except warns users not to
/// use the problematic filters navigation.
struct SafeConsoleView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            ConsoleView()

            // Warning banner about filters crash
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)

                Text("Avoid \"Message Filters\" and \"Network Filters\" - they will crash the app")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 4)
            .padding(.bottom, 50)
        }
    }
}
