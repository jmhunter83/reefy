//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreGraphics
import CoreText
import Foundation
import MediaAccessibilityKit
import SwiftVLC

// SPIKE: caption-style spike, not for release.
//
// Maps the system caption style (Settings > Accessibility > Subtitles & Captioning)
// onto libVLC's text renderer. libVLC 4 only reads `freetype-*` at instance level;
// the `:freetype-*` media options in `VLCMediaPlayerProxy.play` are ignored
// (checked against the same libVLC build on macOS), so the style has to go here.
//
// Known gaps: no separate window box, no live update while playing (needs a new
// instance), and CEA-608 keeps its own text color and size.
enum VLCCaptionStyle {

    @MainActor
    private static var instances: [[String]: VLCInstance] = [:]

    /// One instance per distinct style, since libVLC reads these options once.
    @MainActor
    static func instance(for style: CaptionStyle = .current) -> VLCInstance {
        let arguments = VLCInstance.defaultArguments + arguments(for: style)

        if let instance = instances[arguments] {
            return instance
        }

        guard let instance = try? VLCInstance(arguments: arguments) else {
            return .shared
        }

        instances[arguments] = instance
        return instance
    }

    static func arguments(for style: CaptionStyle) -> [String] {
        var arguments: [String] = []

        if let color = rgb(style.text.color.value) {
            arguments.append("--freetype-color=\(color)")
        }
        arguments.append("--freetype-opacity=\(byte(style.text.opacity.value))")

        // libVLC draws one box behind the text. tvOS presets mostly use the window
        // fill, so fall back to it when the text background is clear.
        let usesWindow = style.textBackground.opacity.value == 0 && style.window.opacity.value > 0
        let boxColor = usesWindow ? style.window.color.value : style.textBackground.color.value
        let boxOpacity = usesWindow ? style.window.opacity.value : style.textBackground.opacity.value

        if let color = rgb(boxColor) {
            arguments.append("--freetype-background-color=\(color)")
        }
        arguments.append("--freetype-background-opacity=\(byte(boxOpacity))")

        // CEA-608 draws its own black box unless this is off.
        if boxOpacity == 0 {
            arguments.append("--no-cc-opaque")
        }

        // Private system names like .AppleSystemUIFont make libVLC fall back to a
        // serif, so keep libVLC's default font for those.
        if let family = family(of: style.text.fonts.default.value), !family.hasPrefix(".") {
            arguments.append("--freetype-font=\(family)")
            // CEA-608 renders with the monospace font slot.
            arguments.append("--freetype-monofont=\(family)")
        }

        // libVLC draws the shadow from the outline, so shadow styles keep a thin
        // invisible outline. With thickness 0 the shadow disappears.
        let shadow = ["--freetype-outline-thickness=2", "--freetype-outline-opacity=0", "--freetype-shadow-opacity=255"]

        switch style.text.edgeStyle.value {
        case .none:
            arguments += ["--freetype-outline-thickness=0", "--freetype-shadow-opacity=0"]
        case .uniform:
            arguments += ["--freetype-outline-thickness=4", "--freetype-shadow-opacity=0"]
        case .dropShadow:
            arguments += shadow + ["--freetype-shadow-distance=0.1"]
        case .raised:
            arguments += shadow + ["--freetype-shadow-angle=-45", "--freetype-shadow-distance=0.04"]
        case .depressed:
            arguments += shadow + ["--freetype-shadow-angle=135", "--freetype-shadow-distance=0.04"]
        case .unspecified, .unknown:
            break
        }

        return arguments
    }

    private static func rgb(_ color: CGColor) -> Int? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = color.converted(to: space, intent: .defaultIntent, options: nil),
              let components = converted.components,
              components.count >= 3
        else { return nil }

        return (byte(components[0]) << 16) | (byte(components[1]) << 8) | byte(components[2])
    }

    private static func byte(_ value: CGFloat) -> Int {
        Int((min(max(value, 0), 1) * 255).rounded())
    }

    private static func family(of font: CaptionFont) -> String? {
        CTFontDescriptorCopyAttribute(font.descriptor, kCTFontFamilyNameAttribute) as? String
    }
}
