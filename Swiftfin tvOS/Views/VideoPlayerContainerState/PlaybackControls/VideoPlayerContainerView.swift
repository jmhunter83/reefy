//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

extension VideoPlayer {
    struct VideoPlayerContainerView<Player: View, PlaybackControls: View>: UIViewControllerRepresentable {

        private let containerState: VideoPlayerContainerState
        private let manager: MediaPlayerManager
        private let player: () -> Player
        private let playbackControls: () -> PlaybackControls

        init(
            containerState: VideoPlayerContainerState,
            manager: MediaPlayerManager,
            @ViewBuilder player: @escaping () -> Player,
            @ViewBuilder playbackControls: @escaping () -> PlaybackControls
        ) {
            self.containerState = containerState
            self.manager = manager
            self.player = player
            self.playbackControls = playbackControls
        }

        func makeUIViewController(context: Context) -> UIVideoPlayerContainerViewController {
            UIVideoPlayerContainerViewController(
                containerState: containerState,
                manager: manager,
                player: player().eraseToAnyView(),
                playbackControls: playbackControls().eraseToAnyView()
            )
        }

        func updateUIViewController(
            _ uiViewController: UIVideoPlayerContainerViewController,
            context: Context
        ) {}
    }

    // MARK: - UIVideoPlayerContainerViewController

    class UIVideoPlayerContainerViewController: UIViewController {

        private struct PlayerContainerView: View {

            @EnvironmentObject
            private var containerState: VideoPlayerContainerState

            let player: AnyView

            var body: some View {
                player
                    .overlay(Color.black.opacity(containerState.isPresentingPlaybackControls ? 0.3 : 0.0))
                    .animation(.linear(duration: 0.2), value: containerState.isPresentingPlaybackControls)
            }
        }

        private lazy var playerViewController: UIHostingController<AnyView> = {
            let controller = UIHostingController(
                rootView: PlayerContainerView(player: player)
                    .environmentObject(containerState)
                    .environmentObject(manager)
                    .eraseToAnyView()
            )
            controller.disableSafeArea()
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            return controller
        }()

        private lazy var playbackControlsViewController: UIHostingController<AnyView> = {
            let content = ZStack {
                GestureView()
                    .environment(\.panGestureDirection, .vertical)

                playbackControls
                    .environment(\.onPressEventPublisher, onPressEvent)
                    .environmentObject(containerState)
                    .environmentObject(containerState.scrubbedSeconds)
                    .environmentObject(focusGuide)
                    .environmentObject(manager)
            }
            .environment(
                \.panAction,
                .init(
                    action: { [weak self] translation, velocity, location, _, state in
                        self?.handleSupplementPanAction(
                            translation: translation,
                            velocity: velocity.y,
                            location: location,
                            state: state
                        )
                    }
                )
            )
            .eraseToAnyView()

            let controller = UIHostingController(rootView: content)
            controller.disableSafeArea()
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            return controller
        }()

        private lazy var supplementContainerViewController: UIHostingController<AnyView> = {
            let content = ZStack {
                GestureView()
                    .environment(\.panGestureDirection, .vertical)

                SupplementContainerView()
                    .environmentObject(containerState)
                    .environmentObject(focusGuide)
                    .environmentObject(manager)
            }
            .environment(
                \.panAction,
                .init(
                    action: { [weak self] translation, velocity, location, _, state in
                        self?.handleSupplementPanAction(
                            translation: translation,
                            velocity: velocity.y,
                            location: location,
                            state: state
                        )
                    }
                )
            )
            .eraseToAnyView()

            let controller = UIHostingController(rootView: content)
            controller.disableSafeArea()
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            return controller
        }()

        private var playerView: UIView {
            playerViewController.view
        }

        private var playbackControlsView: UIView {
            playbackControlsViewController.view
        }

        private var supplementContainerView: UIView {
            supplementContainerViewController.view
        }

        private var supplementRegularConstraints: [NSLayoutConstraint] = []
        private var playerRegularConstraints: [NSLayoutConstraint] = []
        private var playbackControlsConstraints: [NSLayoutConstraint] = []

        private lazy var supplementHeightAnchor: NSLayoutConstraint = {
            supplementContainerView.heightAnchor.constraint(
                equalToConstant: supplementContainerOffset
            )
        }()

        private lazy var supplementBottomAnchor: NSLayoutConstraint = {
            supplementContainerView.topAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -dismissedSupplementContainerOffset
            )
        }()

        // MARK: - Pan Gesture State

        private var lastVerticalPanLocation: CGPoint?
        private var verticalPanGestureStartConstant: CGFloat?
        private var isPanning: Bool = false
        private var didStartPanningWithSupplement: Bool = false

        // MARK: - Constants

        private var supplementContainerOffset: CGFloat {
            (view.bounds.height / 3) + EdgeInsets.edgePadding * 2
        }

        private let dismissedSupplementContainerOffset: CGFloat = 50.0 + EdgeInsets.edgePadding * 2
        private let minimumTranslation: CGFloat = 100.0

        private let manager: MediaPlayerManager
        private let player: AnyView
        private let playbackControls: AnyView
        private let containerState: VideoPlayerContainerState

        let focusGuide = FocusGuide()
        let onPressEvent = OnPressEvent()

        private var cancellables: Set<AnyCancellable> = []

        private var isSwallowingMenuPress = false

        // MARK: - Focus Management

        override var preferredFocusEnvironments: [UIFocusEnvironment] {
            if containerState.isPresentingOverlay || containerState.isPresentingSupplement {
                return [playbackControlsViewController]
            }
            return []
        }

        init(
            containerState: VideoPlayerContainerState,
            manager: MediaPlayerManager,
            player: AnyView,
            playbackControls: AnyView
        ) {
            self.containerState = containerState
            self.manager = manager
            self.player = player
            self.playbackControls = playbackControls

            super.init(nibName: nil, bundle: nil)

            containerState.containerView = self
            containerState.manager = manager
            containerState.observePlaybackStatus()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Supplement Pan Action

        func handleSupplementPanAction(
            translation: CGPoint,
            velocity: CGFloat,
            location: CGPoint,
            state: UIGestureRecognizer.State
        ) {
            let yDirection: CGFloat = translation.y > 0 ? -1 : 1
            let newOffset: CGFloat
            let clampedOffset: CGFloat

            if state == .began {
                self.view.layer.removeAllAnimations()
                didStartPanningWithSupplement = containerState.selectedSupplement != nil
                verticalPanGestureStartConstant = supplementBottomAnchor.constant
            }

            if state == .began || state == .changed {
                lastVerticalPanLocation = location
                isPanning = true

                let shouldHaveSupplementPresented = self.supplementBottomAnchor
                    .constant < -(minimumTranslation + dismissedSupplementContainerOffset)

                if shouldHaveSupplementPresented, !containerState.isPresentingSupplement {
                    containerState.selectedSupplement = manager.supplements.first
                } else if !shouldHaveSupplementPresented, containerState.selectedSupplement != nil {
                    containerState.selectedSupplement = nil
                }
            } else {
                lastVerticalPanLocation = nil
                verticalPanGestureStartConstant = nil
                isPanning = false

                let shouldActuallyDismissSupplement = didStartPanningWithSupplement &&
                    (translation.y > minimumTranslation || velocity > 1000)
                if shouldActuallyDismissSupplement {
                    containerState.selectedSupplement = nil
                }

                let shouldActuallyPresentSupplement = !didStartPanningWithSupplement &&
                    (translation.y < -minimumTranslation || velocity < -1000)
                if shouldActuallyPresentSupplement {
                    containerState.selectedSupplement = manager.supplements.first
                }

                let stateToPass: (translation: CGFloat, velocity: CGFloat)? = (
                    translation: translation.y,
                    velocity: velocity
                )
                presentSupplementContainer(containerState.selectedSupplement != nil, with: stateToPass)
                return
            }

            guard let verticalPanGestureStartConstant else { return }

            if (!didStartPanningWithSupplement && yDirection > 0) || (didStartPanningWithSupplement && yDirection < 0) {
                newOffset = verticalPanGestureStartConstant + (translation.y.magnitude * -yDirection)
            } else {
                newOffset = verticalPanGestureStartConstant - (translation.y.magnitude * yDirection)
            }

            clampedOffset = clamp(
                newOffset,
                min: -supplementContainerOffset,
                max: -dismissedSupplementContainerOffset
            )

            // Rubber-band resistance at boundaries
            if newOffset < clampedOffset {
                let excess = clampedOffset - newOffset
                let resistance = pow(excess, 0.7)
                supplementBottomAnchor.constant = clampedOffset - resistance
            } else if newOffset > -dismissedSupplementContainerOffset {
                let excess = newOffset - clampedOffset
                let resistance = pow(excess, 0.5)
                supplementBottomAnchor.constant = clamp(clampedOffset + resistance, min: -dismissedSupplementContainerOffset, max: -50)
            } else {
                supplementBottomAnchor.constant = clampedOffset
            }

            containerState.supplementOffset = supplementBottomAnchor.constant
        }

        // MARK: - Supplement Presentation

        func presentSupplementContainer(
            _ didPresent: Bool,
            with panningState: (translation: CGFloat, velocity: CGFloat)? = nil
        ) {
            guard !isPanning else { return }

            if didPresent {
                self.supplementBottomAnchor.constant = -supplementContainerOffset
            } else {
                self.supplementBottomAnchor.constant = -dismissedSupplementContainerOffset
            }

            containerState.isPresentingPlaybackControls = !didPresent
            containerState.supplementOffset = supplementBottomAnchor.constant

            view.setNeedsLayout()

            if let panningState {
                let velocity = panningState.velocity.magnitude / 1000
                let distance = panningState.translation.magnitude
                let duration = min(max(Double(distance) / Double(velocity * 1000), 0.2), 0.75)

                UIView.animate(
                    withDuration: duration,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: velocity,
                    options: .allowUserInteraction
                ) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            } else {
                UIView.animate(
                    withDuration: 0.75,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0.4,
                    options: .allowUserInteraction
                ) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            }
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .black

            setupViews()
            setupConstraints()
            setupFocusObserver()
            setupScenePhaseObserver()

            let gesture = UITapGestureRecognizer(target: self, action: #selector(ignorePress))
            gesture.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
            view.addGestureRecognizer(gesture)
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            // Stop proxy immediately for instant audio cutoff
            manager.proxy?.stop()
            // Then clean up manager state
            manager.stop()
        }

        private func setupScenePhaseObserver() {
            NotificationCenter.default
                .publisher(for: UIScene.willEnterForegroundNotification)
                .sink { [weak self] _ in
                    guard let self else { return }
                    Task { @MainActor in
                        guard let playbackItem = self.manager.playbackItem else { return }

                        self.manager.logger.info("App returned from background - recreating VLC player to reset decoder")

                        self.manager.playbackItem = playbackItem
                    }
                }
                .store(in: &cancellables)
        }

        private func setupFocusObserver() {
            containerState.$overlayState
                .removeDuplicates()
                .sink { [weak self] (state: OverlayVisibility) in
                    guard let self else { return }
                    if state == .visible {
                        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationTiming.focusUpdateDelay) {
                            self.setNeedsFocusUpdate()
                            self.updateFocusIfNeeded()
                        }
                    }
                }
                .store(in: &cancellables)

            containerState.$supplementState
                .removeDuplicates()
                .sink { [weak self] (state: SupplementVisibility) in
                    guard let self else { return }
                    if state == .open {
                        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationTiming.focusUpdateDelay) {
                            self.setNeedsFocusUpdate()
                            self.updateFocusIfNeeded()
                        }
                    }
                }
                .store(in: &cancellables)
        }

        private func setupViews() {
            addChild(playerViewController)
            view.addSubview(playerView)
            playerViewController.didMove(toParent: self)
            playerView.backgroundColor = .black
            // Prevent player view from participating in focus
            playerView.isUserInteractionEnabled = false

            addChild(playbackControlsViewController)
            view.addSubview(playbackControlsView)
            playbackControlsViewController.didMove(toParent: self)
            playbackControlsView.backgroundColor = .clear
            // Ensure controls can receive focus
            playbackControlsView.isUserInteractionEnabled = true

            addChild(supplementContainerViewController)
            view.addSubview(supplementContainerView)
            supplementContainerViewController.didMove(toParent: self)
            supplementContainerView.backgroundColor = .clear
        }

        private func setupConstraints() {
            playerRegularConstraints = [
                playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playerView.topAnchor.constraint(equalTo: view.topAnchor),
                playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]

            NSLayoutConstraint.activate(playerRegularConstraints)

            // Defer to avoid "Publishing changes from within view updates" warning
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.containerState.supplementOffset = self.supplementBottomAnchor.constant
            }

            supplementRegularConstraints = [
                supplementContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                supplementContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                supplementBottomAnchor,
                supplementHeightAnchor,
            ]

            NSLayoutConstraint.activate(supplementRegularConstraints)

            playbackControlsConstraints = [
                playbackControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playbackControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playbackControlsView.topAnchor.constraint(equalTo: view.topAnchor),
                playbackControlsView.bottomAnchor.constraint(equalTo: supplementContainerView.topAnchor),
            ]

            NSLayoutConstraint.activate(playbackControlsConstraints)
        }

        @objc
        func ignorePress() {}

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            guard let buttonPress = presses.first else {
                super.pressesBegan(presses, with: event)
                return
            }

            // Send event to SwiftUI for overlay toggle handling
            onPressEvent.send((type: buttonPress.type, phase: .began))

            // For Menu button: swallow press when overlay/supplement is visible
            if buttonPress.type == .menu,
               containerState.isPresentingOverlay || containerState.isPresentingSupplement
            {
                isSwallowingMenuPress = true
                return
            }

            // Call super to allow UIKit focus navigation to work
            super.pressesBegan(presses, with: event)
        }

        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            guard let buttonPress = presses.first else {
                super.pressesEnded(presses, with: event)
                return
            }

            // Send ended event to SwiftUI for hold detection
            onPressEvent.send((type: buttonPress.type, phase: .ended))

            // For Menu button: swallow press if we swallowed the began event
            if buttonPress.type == .menu, isSwallowingMenuPress {
                isSwallowingMenuPress = false
                return
            }

            // Call super to allow UIKit focus navigation to work
            super.pressesEnded(presses, with: event)
        }

        override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            guard let buttonPress = presses.first else {
                super.pressesCancelled(presses, with: event)
                return
            }

            // Treat cancelled as ended for hold detection
            onPressEvent.send((type: buttonPress.type, phase: .cancelled))

            // For Menu button: swallow press if we swallowed the began event
            if buttonPress.type == .menu, isSwallowingMenuPress {
                isSwallowingMenuPress = false
                return
            }

            // Call super
            super.pressesCancelled(presses, with: event)
        }
    }
}

extension VideoPlayer.UIVideoPlayerContainerViewController {

    typealias PressEvent = (type: UIPress.PressType, phase: UIPress.Phase)
    typealias OnPressEvent = LegacyEventPublisher<PressEvent>
}

@propertyWrapper
struct OnPressEvent: DynamicProperty {

    @Environment(\.onPressEventPublisher)
    private var publisher

    var wrappedValue: VideoPlayer.UIVideoPlayerContainerViewController.OnPressEvent {
        publisher
    }
}

extension EnvironmentValues {

    @Entry
    var onPressEventPublisher: VideoPlayer.UIVideoPlayerContainerViewController.OnPressEvent = .init()
}
