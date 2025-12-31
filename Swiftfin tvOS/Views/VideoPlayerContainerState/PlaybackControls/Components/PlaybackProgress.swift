//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI
import UIKit

// TODO: bar color default to style
// TODO: remove compact buttons?
// TODO: capsule scale on editing
// TODO: live tv

extension VideoPlayer.PlaybackControls {

    struct PlaybackProgress: View {

        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

        @FocusState
        private var isFocused: Bool

        @State
        private var sliderSize = CGSize.zero

        @State
        private var previewImage: UIImage?

        @State
        private var previewImageTask: Task<Void, Never>?

        /// Used to validate task currency after async operations to prevent race conditions
        @State
        private var previewTaskID: UUID = UUID()

        private var isScrubbing: Bool {
            get {
                containerState.isScrubbing
            }
            nonmutating set {
                containerState.isScrubbing = newValue
            }
        }

        private var previewXOffset: CGFloat {
            let p = sliderSize.width * scrubbedProgress
            return clamp(p, min: 100, max: sliderSize.width - 100)
        }

        private var scrubbedProgress: Double {
            guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
            return scrubbedSeconds / runtime
        }

        private var scrubbedSeconds: Duration {
            scrubbedSecondsBox.value
        }

        private var trickplayPreviewXOffset: CGFloat {
            let previewWidth: CGFloat = 320
            let halfWidth = previewWidth / 2
            let p = sliderSize.width * scrubbedProgress
            return clamp(p, min: halfWidth, max: sliderSize.width - halfWidth)
        }

        @ViewBuilder
        private var trickplayPreview: some View {
            if isScrubbing, let previewImage {
                #if os(tvOS)
                if #available(tvOS 26.0, *) {
                    // tvOS 26+ Liquid Glass frame
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 320, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(4)
                        .glassEffect(.regular, in: .rect(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
                        .offset(x: trickplayPreviewXOffset - sliderSize.width / 2)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else {
                    legacyTrickplayPreview(image: previewImage)
                }
                #else
                legacyTrickplayPreview(image: previewImage)
                #endif
            }
        }

        @ViewBuilder
        private func legacyTrickplayPreview(image: UIImage) -> some View {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 320, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                }
                .offset(x: trickplayPreviewXOffset - sliderSize.width / 2)
                .transition(.opacity)
        }

        @State
        private var isPulsing = false

        @ViewBuilder
        private var liveIndicator: some View {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .scaleEffect(isPulsing ? 1.3 : 0.8)
                    .opacity(isPulsing ? 1.0 : 0.6)
                    .shadow(color: .red.opacity(0.6), radius: isPulsing ? 6 : 2)
                    .animation(
                        .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: isPulsing
                    )

                Text("LIVE")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            #if os(tvOS)
                .background {
                    if #available(tvOS 26.0, *) {
                        Color.clear
                            .glassEffect(.regular.tint(.red.opacity(0.3)), in: .capsule)
                    } else if #available(tvOS 18.0, *) {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Capsule()
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            }
                    } else {
                        Capsule()
                            .fill(Color.red.opacity(0.2))
                    }
                }
            #else
                .background {
                    Capsule()
                        .fill(Color.red.opacity(0.2))
                }
            #endif
                .onAppear {
                        isPulsing = true
                    }
        }

        @ViewBuilder
        private var capsuleSlider: some View {

            let resolution: Double = 100

            CapsuleSlider(
                value: $scrubbedSecondsBox.value.map(
                    getter: {
                        guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
                        return clamp(($0.seconds / runtime.seconds) * resolution, min: 0, max: resolution)
                    },
                    setter: { (manager.item.runtime ?? .zero) * ($0 / resolution) }
                ),
                total: resolution
            )
            .onEditingChanged { isEditing in
                isScrubbing = isEditing
            }
            .frame(height: 50)
        }

        var body: some View {
            VStack(spacing: 10) {
                if manager.item.isLiveStream {
                    liveIndicator
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ZStack(alignment: .bottom) {
                        trickplayPreview
                            .padding(.bottom, 70)

                        capsuleSlider
                            .trackingSize($sliderSize)
                    }

                    SplitTimeStamp()
                }
            }
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.3), value: isFocused)
            .foregroundStyle(isFocused ? Color.white : Color.white.opacity(0.8))
            .onChange(of: scrubbedSeconds) { _, newSeconds in
                guard isScrubbing else { return }
                previewImageTask?.cancel()

                // Generate new task ID to validate after async operation
                let currentTaskID = UUID()
                previewTaskID = currentTaskID

                previewImageTask = Task {
                    guard !Task.isCancelled, currentTaskID == previewTaskID else { return }
                    let image = await manager.playbackItem?.previewImageProvider?.image(for: newSeconds)
                    // Validate task is still current after await to prevent race condition
                    guard !Task.isCancelled, currentTaskID == previewTaskID else { return }
                    previewImage = image
                }
            }
            .onChange(of: isScrubbing) { _, scrubbing in
                if !scrubbing {
                    previewImageTask?.cancel()
                    previewImageTask = nil
                    previewImage = nil
                }
            }
        }
    }
}
