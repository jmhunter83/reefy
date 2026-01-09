//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// TODO: scroll if description too long

struct MediaInfoSupplement: MediaPlayerSupplement {

    let displayTitle: String = "Info"
    let item: BaseItemDto

    var id: String {
        "MediaInfo-\(item.id ?? "any")"
    }

    var videoPlayerBody: some PlatformView {
        InfoOverlay(item: item)
    }
}

extension MediaInfoSupplement {

    private struct InfoOverlay: PlatformView {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        let item: BaseItemDto

        @ViewBuilder
        private var accessoryView: some View {
            DotHStack {
                if item.type == .episode, let seasonEpisodeLocator = item.seasonEpisodeLabel {
                    Text(seasonEpisodeLocator)
                } else if let premiereYear = item.premiereDateYear {
                    Text(premiereYear)
                }

                if let runtime = item.runTimeLabel {
                    Text(runtime)
                }

                if let officialRating = item.officialRating {
                    Text(officialRating)
                }
            }
        }

        @ViewBuilder
        private var fromBeginningButton: some View {
            Button("From Beginning", systemImage: "play.fill") {
                manager.proxy?.setSeconds(.zero)
                manager.setPlaybackRequestStatus(status: .playing)
                containerState.select(supplement: nil)
            }
            #if os(iOS)
            .buttonStyle(.material)
            #endif
            .frame(width: 200, height: 50)
            .font(.subheadline)
            .fontWeight(.semibold)
        }

        // TODO: may need to be a layout for correct overview frame
        //       with scrolling if too long
        var iOSView: some View {
            CompactOrRegularView(
                isCompact: containerState.isCompact
            ) {
                iOSCompactView
            } regularView: {
                iOSRegularView
            }
            .padding(.leading, safeAreaInsets.leading)
            .padding(.trailing, safeAreaInsets.trailing)
            .edgePadding(.horizontal)
            .edgePadding(.bottom)
        }

        @ViewBuilder
        private var iOSCompactView: some View {
            VStack(alignment: .leading) {
                Group {
                    Text(item.displayTitle)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let overview = item.overview {
                        Text(overview)
                            .font(.subheadline)
                            .fontWeight(.regular)
                    }

                    accessoryView
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .allowsHitTesting(false)

                if !item.isLiveStream {
                    Button {
                        manager.proxy?.setSeconds(.zero)
                        manager.setPlaybackRequestStatus(status: .playing)
                        containerState.select(supplement: nil)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .foregroundStyle(.white)

                            Label("From Beginning", systemImage: "play.fill")
                                .fontWeight(.semibold)
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }

        @ViewBuilder
        private var iOSRegularView: some View {
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                // TODO: determine what to do with non-portrait (channel, home video) images
                //       - use aspect ratio?
                PosterImage(
                    item: item,
                    type: item.preferredPosterDisplayType,
                    contentMode: .fit
                )
                .environment(\.isOverComplexContent, true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.displayTitle)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let overview = item.overview {
                        Text(overview)
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .lineLimit(3)
                    }

                    accessoryView
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !item.isLiveStream {
                    VStack {
                        fromBeginningButton
                    }
                }
            }
        }

        var tvOSView: some View {
            TVOSInfoOverlay(item: item)
        }
    }

    // MARK: - tvOS Info Overlay

    private struct TVOSInfoOverlay: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @FocusState
        private var isFocused: Bool

        let item: BaseItemDto

        @ViewBuilder
        private var accessoryView: some View {
            DotHStack {
                if item.type == .episode, let seasonEpisodeLocator = item.seasonEpisodeLabel {
                    Text(seasonEpisodeLocator)
                } else if let premiereYear = item.premiereDateYear {
                    Text(premiereYear)
                }

                if let runtime = item.runTimeLabel {
                    Text(runtime)
                }

                if let officialRating = item.officialRating {
                    Text(officialRating)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 40) {
                    // Poster
                    ImageView(item.imageSource(.primary, maxWidth: 300))
                        .failure {
                            SystemImageContentView(systemName: item.systemImage)
                        }
                        .aspectRatio(2 / 3, contentMode: .fit)
                        .frame(height: 400)
                        .posterBorder()
                        .cornerRadius(12)

                    // Info content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(item.displayTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        accessoryView

                        if let overview = item.overview {
                            Text(overview)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.9))
                                .lineLimit(6)
                                .frame(maxWidth: 800, alignment: .leading)
                        }

                        // From Beginning button
                        if !item.isLiveStream {
                            Button {
                                manager.proxy?.setSeconds(.zero)
                                manager.setPlaybackRequestStatus(status: .playing)
                                containerState.select(supplement: nil)
                            } label: {
                                Label("From Beginning", systemImage: "play.fill")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(isFocused ? .black : .white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 16)
                                    .background {
                                        Capsule()
                                            .fill(isFocused ? Color.white : Color.white.opacity(0.3))
                                    }
                            }
                            .buttonStyle(.plain)
                            .focused($isFocused)
                            .scaleEffect(isFocused ? 1.05 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
                            .padding(.top, 16)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, EdgeInsets.edgePadding * 2)
            }
            .focusSection()
        }
    }
}
