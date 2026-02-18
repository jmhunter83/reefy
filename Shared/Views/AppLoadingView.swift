//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// The loading view for the app when migrations are taking place
struct AppLoadingView: View {

    @State
    private var didFailMigration = false

    private var migrationFailureView: some View {
        VStack(spacing: 30) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 72, weight: .regular))
                .foregroundStyle(Color.red)
                .symbolRenderingMode(.monochrome)

            VStack(spacing: 12) {
                // TODO: L10n - add key "migrationFailed" = "Migration Failed"
                Text("Migration Failed")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                // TODO: L10n - add key "migrationFailedDescription" = "The app data migration failed. This may be due to corrupted data or insufficient storage."
                Text("The app data migration failed. This may be due to corrupted data or insufficient storage.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 600)
            }

            VStack(spacing: 16) {
                // TODO: L10n - add key "recoveryOptions" = "Recovery Options:"
                Text("Recovery Options:")
                    .font(.headline)
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 8) {
                    // TODO: L10n - add key "migrationRecoveryRetry" = "Restart the app to retry the migration"
                    Text("• Restart the app to retry the migration")
                    // TODO: L10n - add key "migrationRecoveryStorage" = "Check available storage space"
                    Text("• Check available storage space")
                    // TODO: L10n - add key "migrationRecoveryReset" = "If the issue persists, you may need to reset app data"
                    Text("• If the issue persists, you may need to reset app data")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 600, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgePadding()
    }

    var body: some View {
        ZStack {
            Color.clear

            if didFailMigration {
                migrationFailureView
            } else {
                ProgressView()
            }
        }
        .onNotification(.didFailMigration) { _ in
            didFailMigration = true
        }
    }
}
