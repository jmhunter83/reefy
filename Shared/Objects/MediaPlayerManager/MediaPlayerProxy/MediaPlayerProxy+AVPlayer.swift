//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Combine
import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

// TODO: After NativeVideoPlayer is removed, can move bindings and
//       observers to AVPlayerView, like the VLC delegate
//       - wouldn't need to have MediaPlayerProxy: MediaPlayerObserver
// TODO: report playback information, see VLCUI.PlaybackInformation (dropped frames, etc.)
// TODO: have set seconds with completion handler

@MainActor
class AVMediaPlayerProxy: VideoMediaPlayerProxy {

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    var isScrubbing: Binding<Bool> = .constant(false)
    var scrubbedSeconds: Binding<Duration> = .constant(.zero)
    var videoSize: PublishedBox<CGSize> = .init(initialValue: .zero)

    let avPlayerLayer: AVPlayerLayer
    let player: AVPlayer

//    private var rateObserver: NSKeyValueObservation!
    private var statusObserver: NSKeyValueObservation!
    private var timeControlStatusObserver: NSKeyValueObservation!
    private var timeObserver: Any!
    private var managerItemObserver: AnyCancellable?
    private var managerStateObserver: AnyCancellable?

    weak var manager: MediaPlayerManager? {
        didSet {
            for var o in observers {
                o.manager = manager
            }

            if let manager {
                managerItemObserver = manager.$playbackItem
                    .sink { playbackItem in
                        if let playbackItem {
                            self.playNew(item: playbackItem)
                        }
                    }

                managerStateObserver = manager.$state
                    .sink { state in
                        switch state {
                        case .stopped:
                            self.playbackStopped()
                        default: break
                        }
                    }
            } else {
                managerItemObserver?.cancel()
                managerStateObserver?.cancel()
            }
        }
    }

    var observers: [any MediaPlayerObserver] = [
        NowPlayableObserver(),
    ]

    init() {
        self.player = AVPlayer()
        self.avPlayerLayer = AVPlayerLayer(player: player)

        // Capture bindings before closure to avoid main-actor isolation issues
        let isScrubbing = self.isScrubbing
        let scrubbedSeconds = self.scrubbedSeconds

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1000),
            queue: .main
        ) { [weak self] newTime in
            MainActor.assumeIsolated {
                let newSeconds = Duration.seconds(newTime.seconds)

                if !isScrubbing.wrappedValue {
                    scrubbedSeconds.wrappedValue = newSeconds
                }

                self?.manager?.seconds = newSeconds
            }
        }
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
    }

    func jumpForward(_ seconds: Duration) {
        let currentTime = player.currentTime()
        let newTime = currentTime + CMTime(seconds: seconds.seconds, preferredTimescale: 1)
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func jumpBackward(_ seconds: Duration) {
        let currentTime = player.currentTime()
        let newTime = max(.zero, currentTime - CMTime(seconds: seconds.seconds, preferredTimescale: 1))
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setSeconds(_ seconds: Duration) {
        let time = CMTime(seconds: seconds.seconds, preferredTimescale: 1)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setRate(_ rate: Float) {
        player.rate = rate
    }

    func setAudioStream(_ stream: MediaStream) {
        guard let playerItem = player.currentItem else { return }
        guard let group = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) else { return }

        // Find matching option by index
        if let index = stream.index {
            let options = group.options
            if index >= 0, index < options.count {
                playerItem.select(options[index], in: group)
            }
        }
    }

    func setSubtitleStream(_ stream: MediaStream) {
        guard let playerItem = player.currentItem else { return }
        guard let group = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else { return }

        // Handle "Off" (index -1)
        if stream.index == -1 {
            playerItem.select(nil, in: group)
            return
        }

        // Find matching option by index
        if let index = stream.index {
            let options = group.options
            if index < options.count {
                playerItem.select(options[index], in: group)
            }
        }
    }

    func setAspectFill(_ aspectFill: Bool) {
        avPlayerLayer.videoGravity = aspectFill ? .resizeAspectFill : .resizeAspect
    }

    var videoPlayerBody: some View {
        AVPlayerView()
            .environmentObject(self)
    }

    deinit {
        // CRITICAL: Remove time observer synchronously before deallocation
        // Apple docs: "You must remove the time observer before deallocating the player"
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }

        statusObserver?.invalidate()
        timeControlStatusObserver?.invalidate()
        managerItemObserver?.cancel()
        managerStateObserver?.cancel()
    }
}

extension AVMediaPlayerProxy {

    private func playbackStopped() {
        player.pause()

        // Remove time observer synchronously - async dispatch may not execute before deallocation
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        if let statusObserver {
            statusObserver.invalidate()
            self.statusObserver = nil
        }

        if let timeControlStatusObserver {
            timeControlStatusObserver.invalidate()
            self.timeControlStatusObserver = nil
        }
    }

    private func playNew(item: MediaPlayerItem) {
        // Invalidate existing observers before creating new ones
        statusObserver?.invalidate()
        statusObserver = nil
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = nil

        let newAVPlayerItem = AVPlayerItem(url: item.url)
        newAVPlayerItem.externalMetadata = item.baseItem.avMetadata

        player.replaceCurrentItem(with: newAVPlayerItem)

        // Extract values from baseItem before closure to avoid capturing non-Sendable type
        let baseItemStartSeconds = item.baseItem.startSeconds
        let resumeOffset = Defaults[.VideoPlayer.resumeOffset]

        // TODO: protect against paused
//        rateObserver = player.observe(\.rate, options: [.new, .initial]) { _, value in
//            DispatchQueue.main.async {
//                self.manager?.set(rate: value.newValue ?? 1.0)
//            }
//        }

        timeControlStatusObserver = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
            let timeControlStatus = player.timeControlStatus

            Task { @MainActor in
                guard let self else { return }
                switch timeControlStatus {
                case .waitingToPlayAtSpecifiedRate:
                    self.isBuffering.value = true
                case .playing:
                    self.isBuffering.value = false
                    self.manager?.setPlaybackRequestStatus(status: .playing)
                case .paused:
                    self.isBuffering.value = false
                    self.manager?.setPlaybackRequestStatus(status: .paused)
                @unknown default: ()
                }
            }
        }

        // TODO: proper handling of none/unknown states
        statusObserver = player.observe(\.currentItem?.status, options: [.new, .initial]) { [weak self] _, value in
            guard let self, let newValue = value.newValue else { return }
            switch newValue {
            case .failed:
                if let error = self.player.error {
                    Task { @MainActor in
                        self.manager?.error(ErrorMessage("AVPlayer error: \(error.localizedDescription)"))
                    }
                }
            case .none, .readyToPlay, .unknown:
                let startSeconds = max(.zero, (baseItemStartSeconds ?? .zero) - Duration.seconds(resumeOffset))

                self.player.seek(
                    to: CMTimeMake(
                        value: startSeconds.components.seconds,
                        timescale: 1
                    ),
                    toleranceBefore: .zero,
                    toleranceAfter: .zero,
                    completionHandler: { [weak self] _ in
                        Task { @MainActor in
                            self?.play()
                        }
                    }
                )
            @unknown default: ()
            }
        }
    }
}

// MARK: - AVPlayerView

extension AVMediaPlayerProxy {

    struct AVPlayerView: UIViewRepresentable {

        @EnvironmentObject
        private var proxy: AVMediaPlayerProxy
        @EnvironmentObject
        private var scrubbedSeconds: PublishedBox<Duration>

        func makeUIView(context: Context) -> UIView {
//            proxy.isScrubbing = context.environment.isScrubbing
//            proxy.scrubbedSeconds = $scrubbedSeconds.value
            UIAVPlayerView(proxy: proxy)
        }

        func updateUIView(_ uiView: UIView, context: Context) {}
    }

    private class UIAVPlayerView: UIView {

        let proxy: AVMediaPlayerProxy

        init(proxy: AVMediaPlayerProxy) {
            self.proxy = proxy
            super.init(frame: .zero)
            layer.addSublayer(proxy.avPlayerLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            proxy.avPlayerLayer.frame = bounds
        }
    }
}
