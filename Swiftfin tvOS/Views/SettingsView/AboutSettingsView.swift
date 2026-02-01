//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct AboutSettingsView: View {

    @Default(.showWelcomeAfterUpdate)
    private var showWelcomeAfterUpdate
    @Default(.showWelcomeEveryLaunch)
    private var showWelcomeEveryLaunch
    @Default(.enableRemoteNotices)
    private var enableRemoteNotices

    @Router
    private var router

    @EnvironmentObject
    private var welcomeManager: WelcomeManager

    var body: some View {
        Form {
            appInfoSection
            welcomeScreenSection
        }
        .navigationTitle(L10n.about)
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        Section(L10n.application) {
            HStack {
                Text(L10n.version)
                Spacer()
                Text(Bundle.appVersion)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(L10n.build)
                Spacer()
                Text(Bundle.buildNumber)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Build Type")
                Spacer()
                Text(Bundle.buildType.name)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Welcome Screen Section

    private var welcomeScreenSection: some View {
        Section {
            Toggle(L10n.showWelcomeAfterUpdate, isOn: $showWelcomeAfterUpdate)

            Toggle(L10n.showWelcomeEveryLaunch, isOn: $showWelcomeEveryLaunch)

            Toggle(L10n.enableRemoteNotices, isOn: $enableRemoteNotices)

            Button(L10n.showWelcomeScreen) {
                welcomeManager.showWelcome()
            }
        } header: {
            Text(L10n.welcomeScreen)
        } footer: {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.showWelcomeAfterUpdateDescription)
                Text(L10n.showWelcomeEveryLaunchDescription)
                if enableRemoteNotices {
                    Text(L10n.enableRemoteNoticesDescription)
                }
            }
        }
    }
}
