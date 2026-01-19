//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

struct RotateContentView: UIViewControllerRepresentable {

    @ObservedObject
    var proxy: Proxy

    func makeUIViewController(context: Context) -> UIRotateContentViewController {
        UIRotateContentViewController(proxy: proxy)
    }

    func updateUIViewController(_ uiViewController: UIRotateContentViewController, context: Context) {}

    class Proxy: ObservableObject {

        weak var viewController: UIRotateContentViewController?

        func update(_ content: () -> any View) {
            viewController?.updateContent(content())
        }
    }
}

/// A view controller that manages rotating content with proper hosting controller containment.
/// This fixes tvOS focus replication warnings by using UIViewControllerRepresentable pattern.
class UIRotateContentViewController: UIViewController {

    var proxy: RotateContentView.Proxy
    private var currentHostingController: UIHostingController<AnyView>?

    init(proxy: RotateContentView.Proxy) {
        self.proxy = proxy
        super.init(nibName: nil, bundle: nil)
        proxy.viewController = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    func updateContent(_ newContent: any View) {
        let newHostingController = UIHostingController(rootView: AnyView(newContent), ignoreSafeArea: true)
        newHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        newHostingController.view.backgroundColor = .clear

        // Remove old hosting controller with proper containment
        if let oldController = currentHostingController {
            oldController.willMove(toParent: nil)
            UIView.animate(withDuration: 0.3) {
                oldController.view.alpha = 0
            } completion: { _ in
                oldController.view.removeFromSuperview()
                oldController.removeFromParent()
            }
        }

        // Add new hosting controller with proper containment
        newHostingController.view.alpha = 0
        addChild(newHostingController)
        view.addSubview(newHostingController.view)
        newHostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            newHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            newHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            newHostingController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            newHostingController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])

        UIView.animate(withDuration: 0.3) {
            newHostingController.view.alpha = 1
        }

        currentHostingController = newHostingController
    }
}
