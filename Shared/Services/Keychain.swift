//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import KeychainSwift

extension Container {

    // Security: KeychainSwift initialized with defaults; individual keys
    // use .accessibleWhenUnlockedThisDeviceOnly (enforced at each write site in SwiftinStore+UserState.swift)
    var keychainService: Factory<KeychainSwift> {
        self { KeychainSwift() }.singleton
    }
}
