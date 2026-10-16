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

/// Draws VLC subtitles in the tvOS caption style (Settings > Accessibility > Subtitles &
/// Captioning) once the user has customized it. Otherwise VLC keeps its own look.
///
/// libVLC 4 only reads `freetype-*` when an instance is created. The `:freetype-*` media
/// options in `VLCMediaPlayerProxy.play` are ignored, so the style goes on the instance,
/// and a change shows up the next time the player opens.
///
/// libVLC can't match Apple's renderer exactly. It has one box behind the text rather than
/// a separate window, raised and depressed edges are angled shadows, and CEA-608 captions
/// keep their own text color and size.
enum VLCCaptionStyle {

    @MainActor
    private static var cached: (arguments: [String], instance: VLCInstance)?

    @MainActor
    static func instance(for style: CaptionStyle = .current) -> VLCInstance {
        guard style.isCustomized else { return .shared }

        let arguments = VLCInstance.defaultArguments + arguments(for: style)

        if let cached, cached.arguments == arguments {
            return cached.instance
        }

        guard let instance = try? VLCInstance(arguments: arguments) else {
            return .shared
        }

        cached = (arguments, instance)
        return instance
    }

    /// Multiplier for the app's own subtitle size setting.
    static func sizeScale(for style: CaptionStyle = .current) -> Double {
        style.isCustomized ? Double(style.text.sizeScale.value) : 1
    }

    static func arguments(for style: CaptionStyle) -> [String] {
        var arguments: [String] = []

        if let color = rgb(style.text.color.value) {
            arguments.append("--freetype-color=\(color)")
        }
        arguments.append("--freetype-opacity=\(byte(style.text.opacity.value))")

        // tvOS presets mostly use the window fill, so use it when the text background is clear.
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

        // Private system names like .AppleSystemUIFont make libVLC fall back to a serif,
        // so those keep libVLC's default font.
        if let family = family(of: style.text.fonts.default.value), !family.hasPrefix(".") {
            arguments.append("--freetype-font=\(family)")
            // CEA-608 renders with the monospace font.
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
