//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Bundle {

    var appVersion: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var buildNumber: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }

    var displayVersion: String {
        if let version = appVersion {
            if let build = buildNumber, BuildType.current.isDevelopment {
                return "\(version) (Build \(build))"
            }
            return version
        }
        return "Unknown"
    }

    static var appVersion: String {
        Bundle.main.appVersion ?? "Unknown"
    }

    static var buildNumber: String {
        Bundle.main.buildNumber ?? "Unknown"
    }

    static var buildType: BuildType {
        BuildType.current
    }
}

enum BuildType {
    case appStore
    case testFlight
    case debug

    static var current: BuildType {
        #if DEBUG
        return .debug
        #else
        if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
            return .testFlight
        }
        return .appStore
        #endif
    }

    var isDevelopment: Bool {
        self == .debug || self == .testFlight
    }

    var name: String {
        switch self {
        case .appStore: return "App Store"
        case .testFlight: return "TestFlight"
        case .debug: return "Debug"
        }
    }
}
