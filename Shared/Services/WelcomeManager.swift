//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

@MainActor
final class WelcomeManager: ObservableObject {

    static let shared = WelcomeManager()

    @Published
    var shouldShowWelcome = false
    @Published
    var changelog: ChangelogEntry?
    @Published
    var remoteNotices: [RemoteNotice] = []

    private init() {}

    func checkShouldShowWelcome() {
        // Development builds always show
        if BuildType.current.isDevelopment {
            changelog = AppChangelog.current
            shouldShowWelcome = changelog != nil
            return
        }

        // App Store: check settings
        if Defaults[.showWelcomeEveryLaunch] {
            changelog = AppChangelog.current
            shouldShowWelcome = changelog != nil
            return
        }

        if Defaults[.showWelcomeAfterUpdate] {
            guard let currentVersion = Bundle.main.appVersion else { return }

            if currentVersion != Defaults[.lastSeenAppVersion] {
                changelog = AppChangelog.current
                shouldShowWelcome = changelog != nil
            }
        }
    }

    func markWelcomeSeen() {
        if let currentVersion = Bundle.main.appVersion {
            Defaults[.lastSeenAppVersion] = currentVersion
        }

        // Auto-disable "Show After Update" for App Store builds
        if !BuildType.current.isDevelopment {
            Defaults[.showWelcomeAfterUpdate] = false
        }

        shouldShowWelcome = false
    }

    func fetchRemoteNotices() async {
        guard Defaults[.enableRemoteNotices] else { return }
        guard let currentVersion = Bundle.main.appVersion else { return }

        // TODO: Replace with actual Cloudflare Worker URL
        guard let url = URL(string: "https://reefy-notices.workers.dev/") else { return }

        var request = URLRequest(url: url)
        request.setValue(currentVersion, forHTTPHeaderField: "X-App-Version")
        request.setValue("tvos", forHTTPHeaderField: "X-Platform")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(RemoteNoticesResponse.self, from: data)

            let unseenNotices = response.notices.filter { notice in
                notice.isApplicable(to: currentVersion) &&
                    !Defaults[.lastSeenNoticeIDs].contains(notice.id)
            }

            if !unseenNotices.isEmpty {
                self.remoteNotices = unseenNotices
            }
        } catch {
            // Silently fail - remote notices are optional
        }
    }

    func markNoticesSeen() {
        let noticeIDs = Set(remoteNotices.map(\.id))
        Defaults[.lastSeenNoticeIDs].formUnion(noticeIDs)
        remoteNotices = []
    }

    func showWelcome() {
        changelog = AppChangelog.current
        shouldShowWelcome = changelog != nil
    }
}
