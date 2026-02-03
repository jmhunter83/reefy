//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Nuke
import SwiftUI

struct AppSettingsView: View {

    @Default(.selectUserUseSplashscreen)
    private var selectUserUseSplashscreen
    @Default(.selectUserAllServersSplashscreen)
    private var selectUserAllServersSplashscreen

    @Default(.appAppearance)
    private var appearance

    @Router
    private var router

    @StateObject
    private var viewModel = SettingsViewModel()

    @State
    private var resetUserSettingsSelected: Bool = false
    @State
    private var removeAllServersSelected: Bool = false
    @State
    private var showLogsWarning = false
    @State
    private var showClearCacheConfirmation = false
    @State
    private var cacheCleared = false

    private var selectedServer: ServerState? {
        viewModel.servers.first { server in
            selectUserAllServersSplashscreen == .server(id: server.id)
        }
    }

    var body: some View {
        Form(image: .reefyLogo) {
            LabeledContent(
                L10n.version,
                value: "\(UIApplication.appVersion ?? .emptyDash) (\(UIApplication.bundleVersion ?? .emptyDash))"
            )

            Section {
                Toggle(L10n.useSplashscreen, isOn: $selectUserUseSplashscreen)

                if selectUserUseSplashscreen {
                    ListRowMenu(L10n.servers) {
                        if selectUserAllServersSplashscreen == .all {
                            Label(L10n.random, systemImage: "dice.fill")
                        } else if let selectedServer {
                            Text(selectedServer.name)
                        } else {
                            Text(L10n.none)
                        }
                    } content: {
                        Picker(L10n.servers, selection: $selectUserAllServersSplashscreen) {
                            Label(L10n.random, systemImage: "dice.fill")
                                .tag(SelectUserServerSelection.all)

                            ForEach(viewModel.servers) { server in
                                Text(server.name)
                                    .tag(SelectUserServerSelection.server(id: server.id))
                            }
                        }
                    }
                }
            } header: {
                Text(L10n.splashscreen)
            } footer: {
                if selectUserUseSplashscreen {
                    Text(L10n.splashscreenFooter)
                }
            }

            SignOutIntervalSection()

            Section {
                Button(role: .destructive) {
                    showClearCacheConfirmation = true
                } label: {
                    HStack {
                        Text("Clear Image Cache")
                        if cacheCleared {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            } header: {
                Text("Cache")
            } footer: {
                Text(
                    "Clears cached poster images and backdrops. Use this if images appear incorrect after updating metadata on your Jellyfin server."
                )
            }

            Section {
                ChevronButton(L10n.logs) {
                    showLogsWarning = true
                }
            }
        }
        .navigationTitle(L10n.advanced)
        .alert("Clear Image Cache?", isPresented: $showClearCacheConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear Cache", role: .destructive) {
                clearImageCache()
            }
        } message: {
            Text(
                "This will remove all cached poster images and backdrops. They will be re-downloaded from your Jellyfin server when needed."
            )
        }
        .alert("Proceed with Caution", isPresented: $showLogsWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Open Logs") {
                router.route(to: .log)
            }
        } message: {
            Text("The logs feature may be unstable on some tvOS versions. If the app closes unexpectedly, simply reopen it.")
        }
    }

    private func clearImageCache() {
        // Clear Nuke image caches
        ImagePipeline.Swiftfin.posters.cache.removeAll()
        DataCache.Swiftfin.posters?.removeAll()

        // Show confirmation
        cacheCleared = true

        // Reset confirmation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            cacheCleared = false
        }
    }
}
