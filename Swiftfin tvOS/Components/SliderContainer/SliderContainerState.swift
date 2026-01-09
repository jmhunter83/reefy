//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine

class SliderContainerState<Value: BinaryFloatingPoint>: ObservableObject {

    @Published
    var isEditing: Bool
    @Published
    var isFocused: Bool
    @Published
    var value: Value
    @Published
    var clickCount: Int

    let total: Value

    /// Skip labels for 1, 2, 3 clicks
    static var skipLabels: [String] { [":15", "2:00", "5:00"] }

    /// Current skip label based on click count
    var currentSkipLabel: String {
        let index = max(0, clickCount - 1)
        return Self.skipLabels[min(index, Self.skipLabels.count - 1)]
    }

    init(
        isEditing: Bool,
        isFocused: Bool,
        value: Value,
        total: Value,
        clickCount: Int = 0
    ) {
        self.isEditing = isEditing
        self.isFocused = isFocused
        self.value = value
        self.total = total
        self.clickCount = clickCount
    }
}
