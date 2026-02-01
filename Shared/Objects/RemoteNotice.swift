//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct RemoteNotice: Codable, Identifiable {
    let id: String
    let title: String
    let message: String
    let minVersion: String?
    let maxVersion: String?
    let expiresAt: Date?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() > expiresAt
    }

    func isApplicable(to version: String) -> Bool {
        if isExpired { return false }

        if let min = minVersion, version < min { return false }
        if let max = maxVersion, version > max { return false }

        return true
    }
}

struct RemoteNoticesResponse: Codable {
    let notices: [RemoteNotice]
}
