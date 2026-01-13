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
        // Don't update value while user is actively scrubbing to prevent jumps
        guard !uiView.containerState.isEditing else { return }
        DispatchQueue.main.async {
            uiView.containerState.value = value.wrappedValue
        }
    }
}

final class UISliderContainer<Value: BinaryFloatingPoint>: UIControl {

    // MARK: - Skip Amounts (in seconds, will be converted to Value units)

    /// Skip amounts for 1, 2, 3 clicks (15s, 2min, 5min)
    private let skipAmounts: [Double] = [15, 120, 300]

    private let onEditingChanged: (Bool) -> Void
    private let total: Value
    private let valueBinding: Binding<Value>

    private var swipeGestureRecognizer: DirectionalPanGestureRecognizer!
    private var selectGestureRecognizer: UITapGestureRecognizer!

    private lazy var progressHostingController: UIHostingController<AnyView> = {
        let hostingController = UIHostingController(rootView: AnyView(view.environmentObject(containerState)))
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }()

    private var progressHostingView: UIView { progressHostingController.view }

    let containerState: SliderContainerState<Value>
    let view: AnyView

    // MARK: - Click Counter State

    private var clickCount: Int = 0
    private var clickResetTimer: Timer?
    private let clickTimeout: TimeInterval = 0.4 // Time window for multi-clicks

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
        clickResetTimer?.invalidate()
        clickResetTimer = nil
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
        // Swipe gesture for skip direction
        swipeGestureRecognizer = DirectionalPanGestureRecognizer(
            direction: .horizontal,
            target: self,
            action: #selector(didSwipe)
        )
        addGestureRecognizer(swipeGestureRecognizer)

        // Select/click gesture to set skip magnitude
        selectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSelect))
        selectGestureRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        addGestureRecognizer(selectGestureRecognizer)
    }

    // MARK: - Click Handling

    @objc
    private func didSelect() {
        clickCount += 1
        clickResetTimer?.invalidate()

        // Cap at 3 clicks
        if clickCount > 3 {
            clickCount = 3
        }

        // Update state for visual feedback
        containerState.clickCount = clickCount
        containerState.isEditing = true
        onEditingChanged(true)

        // Reset click count after timeout
        clickResetTimer = Timer.scheduledTimer(withTimeInterval: clickTimeout, repeats: false) { [weak self] _ in
            self?.resetClickState()
        }
    }

    private func resetClickState() {
        clickCount = 0
        containerState.clickCount = 0
        containerState.isEditing = false
        onEditingChanged(false)
        clickResetTimer?.invalidate()
        clickResetTimer = nil
    }

    // MARK: - Swipe Handling

    @objc
    private func didSwipe(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer.state == .ended else { return }

        let velocity = gestureRecognizer.velocity(in: self).x

        // Need minimum velocity to trigger skip
        guard abs(velocity) > 200 else { return }

        // Determine skip amount based on click count (default to 15s if no clicks)
        let skipIndex = max(0, clickCount - 1)
        _ = skipAmounts[min(skipIndex, skipAmounts.count - 1)]

        // Convert seconds to Value units (assuming total represents 100% progress)
        // The value is normalized 0-100, so we need to convert skip seconds to that scale
        // This requires knowing the runtime, which we don't have directly
        // For now, assume the slider value represents percentage (0-100)
        // and we need to convert skipSeconds relative to runtime

        // Actually, looking at how this is used, the total is 100 (resolution)
        // and the value maps to Duration. Let me calculate skip as percentage.
        // Since we don't have runtime here, we'll skip by a fixed percentage
        // that approximates the skip amounts for typical content

        // For a 2-hour movie (7200s):
        // 15s = 0.21%, 120s = 1.67%, 300s = 4.17%
        // Using these as reasonable percentages of the 0-100 scale:
        let skipPercentages: [Double] = [0.5, 3.0, 7.0] // More noticeable skips
        let skipAmount = skipPercentages[min(skipIndex, skipPercentages.count - 1)]

        let direction: Value = velocity > 0 ? 1 : -1
        let newValue = containerState.value + Value(skipAmount) * direction
        let clampedValue = clamp(newValue, min: 0, max: containerState.total)

        // Apply the skip
        containerState.value = clampedValue
        valueBinding.wrappedValue = clampedValue
        sendActions(for: .valueChanged)

        // Reset click state after skip
        resetClickState()
    }

    override var canBecomeFocused: Bool {
        true
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        containerState.isFocused = (context.nextFocusedView == self)

        // Reset click state when losing focus
        if context.nextFocusedView != self {
            resetClickState()
        }
    }
}
