//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SliderContainer<Value: BinaryFloatingPoint>: UIViewRepresentable {

    private var value: Binding<Value>
    private let total: Value
    private let onEditingChanged: (Bool) -> Void
    private let view: AnyView

    init(
        value: Binding<Value>,
        total: Value,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder view: @escaping () -> some SliderContentView
    ) {
        self.value = value
        self.total = total
        self.onEditingChanged = onEditingChanged
        self.view = AnyView(view())
    }

    init(
        value: Binding<Value>,
        total: Value,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        view: AnyView
    ) {
        self.value = value
        self.total = total
        self.onEditingChanged = onEditingChanged
        self.view = view
    }

    func makeUIView(context: Context) -> UISliderContainer<Value> {
        UISliderContainer(
            value: value,
            total: total,
            onEditingChanged: onEditingChanged,
            view: view
        )
    }

    func updateUIView(_ uiView: UISliderContainer<Value>, context: Context) {
        DispatchQueue.main.async {
            uiView.containerState.value = value.wrappedValue
        }
    }
}

final class UISliderContainer<Value: BinaryFloatingPoint>: UIControl {

    private let decelerationMaxVelocity: CGFloat = 1000.0
    private let fineTuningVelocityThreshold: CGFloat = 1000.0
    private let panDampingValue: CGFloat = 50

    private let onEditingChanged: (Bool) -> Void
    private let total: Value
    private let valueBinding: Binding<Value>

    private var panGestureRecognizer: DirectionalPanGestureRecognizer!
    private var selectGestureRecognizer: UITapGestureRecognizer!
    private var menuGestureRecognizer: UITapGestureRecognizer!

    private lazy var progressHostingController: UIHostingController<AnyView> = {
        let hostingController = UIHostingController(rootView: AnyView(view.environmentObject(containerState)))
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }()

    private var progressHostingView: UIView { progressHostingController.view }

    let containerState: SliderContainerState<Value>
    let view: AnyView
    private var decelerationTimer: Timer?

    // MARK: - Scrub Mode State

    /// Whether the user has clicked to enter active scrub mode
    private var isInScrubMode: Bool = false

    /// The value when scrub mode was entered (for cancel)
    private var scrubModeStartValue: Value = 0

    /// The current scrubbed value (before commit)
    private var scrubbedValue: Value = 0

    init(
        value: Binding<Value>,
        total: Value,
        onEditingChanged: @escaping (Bool) -> Void,
        view: AnyView
    ) {
        self.onEditingChanged = onEditingChanged
        self.total = total
        self.valueBinding = value
        self.containerState = .init(
            isEditing: false,
            isFocused: false,
            value: value.wrappedValue,
            total: total
        )
        self.view = view
        super.init(frame: .zero)

        setupViews()
        setupGestureRecognizers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        decelerationTimer?.invalidate()
        decelerationTimer = nil
    }

    private func setupViews() {
        addSubview(progressHostingView)
        NSLayoutConstraint.activate([
            progressHostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressHostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressHostingView.topAnchor.constraint(equalTo: topAnchor),
            progressHostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupGestureRecognizers() {
        // Pan gesture for scrubbing (only active in scrub mode)
        panGestureRecognizer = DirectionalPanGestureRecognizer(
            direction: .horizontal,
            target: self,
            action: #selector(didPan)
        )
        addGestureRecognizer(panGestureRecognizer)

        // Select/click gesture to enter/confirm scrub mode
        selectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSelect))
        selectGestureRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        addGestureRecognizer(selectGestureRecognizer)

        // Menu gesture to cancel scrub mode
        menuGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didPressMenu))
        menuGestureRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        addGestureRecognizer(menuGestureRecognizer)
    }

    // MARK: - Scrub Mode Control

    private func enterScrubMode() {
        guard !isInScrubMode else { return }
        isInScrubMode = true
        scrubModeStartValue = containerState.value
        scrubbedValue = containerState.value
        onEditingChanged(true)
        containerState.isEditing = true
    }

    private func commitScrub() {
        guard isInScrubMode else { return }
        isInScrubMode = false
        // Value is already set during scrubbing
        valueBinding.wrappedValue = scrubbedValue
        containerState.value = scrubbedValue
        onEditingChanged(false)
        containerState.isEditing = false
        stopDeceleratingTimer()
    }

    private func cancelScrub() {
        guard isInScrubMode else { return }
        isInScrubMode = false
        // Restore original value
        containerState.value = scrubModeStartValue
        valueBinding.wrappedValue = scrubModeStartValue
        onEditingChanged(false)
        containerState.isEditing = false
        stopDeceleratingTimer()
    }

    @objc
    private func didSelect() {
        if isInScrubMode {
            // Already scrubbing - commit the seek
            commitScrub()
        } else {
            // Enter scrub mode
            enterScrubMode()
        }
    }

    @objc
    private func didPressMenu() {
        if isInScrubMode {
            // Cancel scrub and restore position
            cancelScrub()
        }
        // If not in scrub mode, let the event propagate (don't handle it)
    }

    private var panDeceleratingVelocity: CGFloat = 0
    private var panStartValue: Value = 0

    @objc
    private func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        // Only respond to pan gestures when in scrub mode
        guard isInScrubMode else { return }

        let translation = gestureRecognizer.translation(in: self).x
        let velocity = gestureRecognizer.velocity(in: self).x

        switch gestureRecognizer.state {
        case .began:
            panStartValue = scrubbedValue
            stopDeceleratingTimer()
        case .changed:
            let dampedTranslation = translation / panDampingValue
            let newValue = panStartValue + Value(dampedTranslation)
            let clampedValue = clamp(newValue, min: 0, max: containerState.total)

            sendActions(for: .valueChanged)

            scrubbedValue = clampedValue
            containerState.value = clampedValue
        // Don't update binding yet - only on commit
        case .ended, .cancelled:
            panStartValue = scrubbedValue

            if abs(velocity) > fineTuningVelocityThreshold {
                let direction: CGFloat = velocity > 0 ? 1 : -1
                panDeceleratingVelocity = (abs(velocity) > decelerationMaxVelocity ? decelerationMaxVelocity * direction : velocity) /
                    panDampingValue
                decelerationTimer = Timer.scheduledTimer(
                    timeInterval: 0.01,
                    target: self,
                    selector: #selector(handleDeceleratingTimer),
                    userInfo: nil,
                    repeats: true
                )
            }
        default:
            break
        }
    }

    @objc
    private func handleDeceleratingTimer(time: Timer) {
        guard isInScrubMode else {
            stopDeceleratingTimer()
            return
        }

        let newValue = panStartValue + Value(panDeceleratingVelocity) * 0.01
        let clampedValue = clamp(newValue, min: 0, max: containerState.total)

        sendActions(for: .valueChanged)
        panStartValue = clampedValue

        panDeceleratingVelocity *= 0.92

        if !isFocused || abs(panDeceleratingVelocity) < 1 {
            stopDeceleratingTimer()
        }

        scrubbedValue = clampedValue
        containerState.value = clampedValue
    }

    private func stopDeceleratingTimer() {
        decelerationTimer?.invalidate()
        decelerationTimer = nil
        panDeceleratingVelocity = 0
        sendActions(for: .valueChanged)
    }

    override var canBecomeFocused: Bool {
        true
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        let wasFocused = containerState.isFocused
        containerState.isFocused = (context.nextFocusedView == self)

        // If losing focus while in scrub mode, cancel the scrub
        if wasFocused && !containerState.isFocused && isInScrubMode {
            cancelScrub()
        }
    }
}
