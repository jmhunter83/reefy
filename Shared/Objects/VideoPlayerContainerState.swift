//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import SwiftUI

// MARK: - State Enums

/// Overlay visibility state
enum OverlayVisibility: Hashable {
    case hidden
    case visible
    case locked // gestures locked, overlay hidden
}

/// Supplement panel state
enum SupplementVisibility: Hashable {
    case closed
    case open
}

/// Scrubbing state
enum ScrubState: Hashable {
    case idle
    case scrubbing
}

@MainActor
class VideoPlayerContainerState: ObservableObject {

    // MARK: - Primary State (enum-based)

    @Published
    private(set) var overlayState: OverlayVisibility = .hidden {
        didSet {
            updatePlaybackControlsVisibility()

            // When overlay becomes visible (not locked), start auto-hide timer
            if overlayState == .visible, supplementState == .closed {
                timer.poke()
            }
        }
    }

    @Published
    private(set) var supplementState: SupplementVisibility = .closed {
        didSet {
            updatePlaybackControlsVisibility()
            presentationControllerShouldDismiss = supplementState == .closed

            switch supplementState {
            case .open:
                timer.stop()
            case .closed:
                isGuestSupplement = false
                timer.poke()
            }
        }
    }

    @Published
    private(set) var scrubState: ScrubState = .idle {
        didSet {
            switch scrubState {
            case .scrubbing:
                timer.stop()
            case .idle:
                timer.poke()
            }
        }
    }

    // MARK: - Computed Properties (backward compatibility)

    /// Whether the overlay is currently visible (not hidden or locked)
    var isPresentingOverlay: Bool {
        get { overlayState == .visible }
        set {
            if isGestureLocked {
                // When locked, ignore attempts to show overlay
                overlayState = .locked
            } else {
                overlayState = newValue ? .visible : .hidden
            }
        }
    }

    /// Whether the supplement panel is currently open
    var isPresentingSupplement: Bool {
        supplementState == .open
    }

    /// Whether the user is currently scrubbing the timeline
    var isScrubbing: Bool {
        get { scrubState == .scrubbing }
        set { scrubState = newValue ? .scrubbing : .idle }
    }

    /// Whether gestures are locked (overlay is hidden and cannot be shown)
    var isGestureLocked: Bool {
        get { overlayState == .locked }
        set {
            if newValue {
                overlayState = .locked
            } else {
                // When unlocking, go to hidden state
                overlayState = .hidden
            }
        }
    }

    // MARK: - Other Published State

    @Published
    var isAspectFilled: Bool = false

    @Published
    var isPresentingPlaybackControls: Bool = false

    @Published
    var isCompact: Bool = false {
        didSet {
            updatePlaybackControlsVisibility()
        }
    }

    @Published
    var isGuestSupplement: Bool = false

    @Published
    var presentationControllerShouldDismiss: Bool = true

    @Published
    var selectedSupplement: (any MediaPlayerSupplement)? = nil {
        didSet {
            supplementState = selectedSupplement != nil ? .open : .closed
        }
    }

    @Published
    var supplementOffset: CGFloat = 0.0

    @Published
    var centerOffset: CGFloat = 0.0

    // MARK: - Components

    let jumpProgressObserver: JumpProgressObserver = .init()
    let scrubbedSeconds: PublishedBox<Duration> = .init(initialValue: .zero)
    let timer: PokeIntervalTimer = .init()
    let toastProxy: ToastProxy = .init()

    weak var containerView: VideoPlayer.UIVideoPlayerContainerViewController?
    weak var manager: MediaPlayerManager?

    #if os(iOS)
    var panHandlingAction: (any _PanHandlingAction)?
    var didSwipe: Bool = false
    var lastTapLocation: CGPoint?
    #endif

    private var jumpProgressCancellable: AnyCancellable?
    private var timerCancellable: AnyCancellable?
    private var playbackStatusCancellable: AnyCancellable?

    // MARK: - Initialization

    init() {
        timerCancellable = timer.sink { [weak self] in
            guard let self else { return }
            guard scrubState == .idle,
                  supplementState == .closed,
                  manager?.playbackRequestStatus != .paused
            else { return }

            withAnimation(.linear(duration: 0.25)) {
                self.overlayState = .hidden
            }
        }

        #if os(iOS)
        jumpProgressCancellable = jumpProgressObserver
            .timer
            .sink { [weak self] in
                self?.lastTapLocation = nil
            }
        #endif
    }

    /// Call this after manager is set to observe playback status
    func observePlaybackStatus() {
        guard let manager else { return }

        playbackStatusCancellable = manager.$playbackRequestStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }

                if status == .paused {
                    // When paused, show overlay and stop timer
                    if self.overlayState != .visible && !self.isGestureLocked {
                        withAnimation(.linear(duration: 0.25)) {
                            self.overlayState = .visible
                        }
                    }
                    self.timer.stop()
                } else if status == .playing {
                    // When playing, start the auto-hide timer
                    if self.overlayState == .visible && self.supplementState == .closed {
                        self.timer.poke()
                    }
                }
            }
    }

    // MARK: - State Mutations

    /// Show or hide the overlay with animation consideration
    func setOverlayVisible(_ visible: Bool, animated: Bool = true) {
        guard !isGestureLocked else { return }

        if animated {
            withAnimation(.linear(duration: 0.25)) {
                overlayState = visible ? .visible : .hidden
            }
        } else {
            overlayState = visible ? .visible : .hidden
        }
    }

    /// Toggle overlay visibility
    func toggleOverlay() {
        setOverlayVisible(overlayState != .visible)
    }

    /// Select a supplement panel to display
    func select(supplement: (any MediaPlayerSupplement)?, isGuest: Bool = false) {
        isGuestSupplement = isGuest

        if supplement?.id == selectedSupplement?.id {
            selectedSupplement = nil
            containerView?.presentSupplementContainer(false)
        } else {
            selectedSupplement = supplement
            containerView?.presentSupplementContainer(supplement != nil)
        }
    }

    // MARK: - Private Helpers

    private func updatePlaybackControlsVisibility() {
        guard overlayState == .visible else {
            isPresentingPlaybackControls = false
            return
        }

        if overlayState == .visible && supplementState == .closed {
            isPresentingPlaybackControls = true
            return
        }

        if isCompact {
            if supplementState == .open {
                if !isPresentingPlaybackControls {
                    isPresentingPlaybackControls = true
                }
            } else {
                isPresentingPlaybackControls = false
            }
        } else {
            isPresentingPlaybackControls = false
        }
    }
}
