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
import VLCUI

/// Inline dropdown picker for audio/subtitle stream selection.
/// Displays as a button that expands into a scrollable list when focused.
struct InlineStreamPicker: View {

    @Environment(\.isFocused)
    private var isFocused

    let title: String
    let systemImage: String
    let streams: [MediaStream]
    let selectedIndex: Int?
    let onSelect: (MediaStream) -> Void

    @State
    private var isExpanded = false

    @State
    private var expandedWidth: CGFloat = 280

    private var selectedStream: MediaStream? {
        guard let index = selectedIndex else { return nil }
        return streams.first { $0.index == index }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if isExpanded {
                expandedList
            } else {
                collapsedButton
            }
        }
    }

    private var collapsedButton: some View {
        TransportBarButton(title) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.callout)
            }
        }
    }

    private var expandedList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with close button
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.2))

            // Stream list
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    // "None" option for subtitles
                    if title == L10n.subtitles {
                        StreamRow(
                            title: L10n.none,
                            subtitle: nil,
                            isSelected: selectedIndex == -1 || selectedIndex == nil,
                            action: {
                                onSelect(.none)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded = false
                                }
                            }
                        )
                    }

                    ForEach(streams, id: \.index) { stream in
                        StreamRow(
                            title: streamTitle(for: stream),
                            subtitle: stream.codec?.uppercased(),
                            isSelected: selectedIndex == stream.index,
                            action: {
                                onSelect(stream)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded = false
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 300)
        }
        .frame(width: expandedWidth)
        .background {
            TransportBarBackground()
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
    }

    private func streamTitle(for stream: MediaStream) -> String {
        if title == L10n.subtitles {
            return stream.formattedSubtitleTitle
        } else {
            return stream.formattedAudioTitle
        }
    }

    // MARK: - Stream Row

    private struct StreamRow: View {

        @Environment(\.isFocused)
        private var isFocused

        let title: String
        let subtitle: String?
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: 12) {
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? .green : .white.opacity(0.4))

                    // Stream info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if let subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isFocused ? Color.white.opacity(0.2) : Color.clear)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
