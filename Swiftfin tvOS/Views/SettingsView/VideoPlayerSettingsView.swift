//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct VideoPlayerSettingsView: View {

    // MARK: - Resume

    @Default(.VideoPlayer.resumeOffset)
    private var resumeOffset

    // MARK: - Sync Offset

    @Default(.VideoPlayer.audioOffset)
    private var audioOffset
    @Default(.VideoPlayer.subtitleOffset)
    private var subtitleOffset

    // MARK: - Action Buttons

    @Default(.VideoPlayer.barActionButtons)
    private var barActionButtons
    @Default(.VideoPlayer.menuActionButtons)
    private var menuActionButtons
    @Default(.VideoPlayer.autoPlayEnabled)
    private var autoPlayEnabled

    // MARK: - Overlay

    @Default(.VideoPlayer.Overlay.chapterSlider)
    private var chapterSlider
    @Default(.VideoPlayer.Overlay.trailingTimestampType)
    private var trailingTimestampType

    // MARK: - Audio

    @Default(.VideoPlayer.Audio.outputMode)
    private var audioOutputMode

    // MARK: - Subtitle

    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize
    @Default(.VideoPlayer.Subtitle.subtitleColor)
    private var subtitleColor

    // MARK: - Preview

    @StoredValue(.User.previewImageScrubbing)
    private var previewImageScrubbing: PreviewImageScrubbingOption

    @Router
    private var router

    @State
    private var isPresentingResumeOffsetStepper: Bool = false
    @State
    private var isPresentingSubtitleSizeStepper: Bool = false
    @State
    private var isPresentingAudioOffsetStepper: Bool = false
    @State
    private var isPresentingSubtitleOffsetStepper: Bool = false

    var body: some View {
        Form(systemImage: "tv") {
            // SECTION: Action Buttons
            Section(L10n.buttons) {
                ChevronButton(L10n.barButtons) {
                    router.route(to: .actionBarButtonSelector(
                        selectedButtonsBinding: $barActionButtons
                    ))
                }

                ChevronButton(L10n.menuButtons) {
                    router.route(to: .actionMenuButtonSelector(
                        selectedButtonsBinding: $menuActionButtons
                    ))
                }
            }
            .onChange(of: barActionButtons) { _, newValue in
                autoPlayEnabled = newValue.contains(.autoPlay) || menuActionButtons.contains(.autoPlay)
            }
            .onChange(of: menuActionButtons) { _, newValue in
                autoPlayEnabled = newValue.contains(.autoPlay) || barActionButtons.contains(.autoPlay)
            }

            // SECTION: Resume Offset
            Section {
                ChevronButton(
                    L10n.offset,
                    subtitle: resumeOffset.secondLabel
                ) {
                    isPresentingResumeOffsetStepper = true
                }
            } header: {
                Text(L10n.resume)
            } footer: {
                Text(L10n.resumeOffsetDescription)
            }

            // SECTION: Slider / Progress
            Section(L10n.slider) {
                Toggle(L10n.chapterSlider, isOn: $chapterSlider)

                ListRowMenu(
                    L10n.previewImage,
                    selection: $previewImageScrubbing
                )
            }

            // SECTION: Timestamp
            Section(L10n.timestamp) {
                ListRowMenu(
                    L10n.trailingValue,
                    selection: $trailingTimestampType
                )
            }

            // SECTION: Audio Output
            Section {
                ListRowMenu(
                    L10n.audioOutputMode,
                    selection: $audioOutputMode
                )
            } header: {
                Text(L10n.audio)
            } footer: {
                Text(audioOutputMode.description)
            }

            // SECTION: Subtitles
            Section {
                ChevronButton(L10n.subtitleFont, subtitle: subtitleFontName) {
                    router.route(to: .fontPicker(selection: $subtitleFontName))
                }

                ChevronButton(
                    L10n.subtitleSize,
                    subtitle: "\(subtitleSize)"
                ) {
                    isPresentingSubtitleSizeStepper = true
                }

                ListRowMenu(L10n.subtitleColor) {
                    Circle()
                        .fill(subtitleColor)
                        .frame(width: 20, height: 20)
                } content: {
                    Picker(L10n.subtitleColor, selection: $subtitleColor) {
                        Text("White").tag(Color.white)
                        Text(L10n.yellow).tag(Color.yellow)
                        Text(L10n.red).tag(Color.red)
                        Text(L10n.green).tag(Color.green)
                        Text(L10n.blue).tag(Color.blue)
                    }
                }
            } header: {
                Text(L10n.subtitles)
            } footer: {
                Text(L10n.subtitlesDisclaimer)
            }

            // SECTION: Sync Offset
            Section {
                ChevronButton(
                    L10n.audio,
                    subtitle: audioOffset.millisecondLabel
                ) {
                    isPresentingAudioOffsetStepper = true
                }

                ChevronButton(
                    L10n.subtitles,
                    subtitle: subtitleOffset.millisecondLabel
                ) {
                    isPresentingSubtitleOffsetStepper = true
                }
            } header: {
                Text("Sync")
            } footer: {
                Text("Adjust audio and subtitle sync in milliseconds")
            }
        }
        .navigationTitle(L10n.videoPlayer.localizedCapitalized)
        .blurredFullScreenCover(isPresented: $isPresentingResumeOffsetStepper) {
            StepperView(
                title: L10n.resumeOffsetTitle,
                description: L10n.resumeOffsetDescription,
                value: $resumeOffset,
                range: 0 ... 30,
                step: 1
            )
            .valueFormatter { $0.secondLabel }
            .onCloseSelected { isPresentingResumeOffsetStepper = false }
        }
        .blurredFullScreenCover(isPresented: $isPresentingSubtitleSizeStepper) {
            StepperView(
                title: L10n.subtitleSize,
                description: L10n.subtitlesDisclaimer,
                value: $subtitleSize,
                range: 1 ... 20,
                step: 1
            )
            .onCloseSelected { isPresentingSubtitleSizeStepper = false }
        }
        .blurredFullScreenCover(isPresented: $isPresentingAudioOffsetStepper) {
            StepperView(
                title: "Audio Offset",
                description: "Adjust audio sync in milliseconds",
                value: $audioOffset,
                range: -5000 ... 5000,
                step: 100
            )
            .valueFormatter { $0.millisecondLabel }
            .onCloseSelected { isPresentingAudioOffsetStepper = false }
        }
        .blurredFullScreenCover(isPresented: $isPresentingSubtitleOffsetStepper) {
            StepperView(
                title: "Subtitle Offset",
                description: "Adjust subtitle sync in milliseconds",
                value: $subtitleOffset,
                range: -5000 ... 5000,
                step: 100
            )
            .valueFormatter { $0.millisecondLabel }
            .onCloseSelected { isPresentingSubtitleOffsetStepper = false }
        }
    }
}
