//
//  SwipeBackGesture.swift
//  Blissful Catholic
//
//  Re-enables the interactive edge swipe-back gesture on pushed screens that hide
//  the system navigation bar and use the custom LumenDeepHeader back button.
//  UIKit disables `interactivePopGestureRecognizer` when there's no standard back
//  button, so we reinstate it with a permissive delegate that still refuses to
//  fire on the root (nothing to pop). Attached once inside LumenDeepHeader, so
//  every screen with the custom back arrow gets the swipe gesture back.
//

import SwiftUI
import UIKit

extension View {
    func enableSwipeBack() -> some View {
        background(SwipeBackEnabler().frame(width: 0, height: 0))
    }
}

private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Enabler { Enabler() }
    func updateUIViewController(_ uiViewController: Enabler, context: Context) {}

    final class Enabler: UIViewController, UIGestureRecognizerDelegate {
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if let gesture = navigationController?.interactivePopGestureRecognizer {
                gesture.delegate = self
                gesture.isEnabled = true
            }
        }

        // Allow the edge swipe whenever there's a screen to pop back to; never on
        // the root (where it would otherwise wedge the navigation stack).
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }
}
