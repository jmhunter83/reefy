//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

struct UserProfileSettingsView: View {

    @Router
    private var router

    @ObservedObject
    private var viewModel: SettingsViewModel
    @StateObject
    private var profileImageViewModel: UserProfileImageViewModel

    @State
    private var isPresentingConfirmReset: Bool = false

    /// Safe access to user session
    private var session: UserSession? {
        viewModel.userSession
    }

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        // Safe init - use optional binding with fallback
        if let session = viewModel.userSession {
            self._profileImageViewModel = StateObject(wrappedValue: UserProfileImageViewModel(user: session.user.data))
        } else {
            // Create with empty UserDto as fallback - view won't display anyway
            self._profileImageViewModel = StateObject(wrappedValue: UserProfileImageViewModel(user: .init()))
        }
    }

    var body: some View {
        if let session {
            Form(content: {
                Section {
                    ChevronButton(L10n.security) {
                        router.route(to: .localSecurity)
                    }
                }

                // TODO: Do we want this option on tvOS?
//            Section {
//                // TODO: move under future "Storage" tab
//                //       when downloads implemented
//                Button(L10n.resetSettings) {
//                    isPresentingConfirmReset = true
//                }
//                .foregroundStyle(.red)
//            } footer: {
//                Text(L10n.resetSettingsDescription)
//            }
            }, image: {
                UserProfileImage(
                    userID: session.user.id,
                    source: session.user.profileImageSource(
                        client: session.client
                    )
                )
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 400)
            })
            .navigationTitle(L10n.user)
            .confirmationDialog(
                L10n.resetSettings,
                isPresented: $isPresentingConfirmReset,
                titleVisibility: .visible
            ) {
                Button(L10n.reset, role: .destructive) {
                    do {
                        try session.user.deleteSettings()
                    } catch {
                        viewModel.logger.error("Unable to reset user settings: \(error.localizedDescription)")
                    }
                }
            } message: {
                Text(L10n.resetSettingsMessage)
            }
        }
    }
}
