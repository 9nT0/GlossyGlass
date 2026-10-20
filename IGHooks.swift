//
//  IGHooks.swift
//  GlossyGlass v5
//
//  Minimal hooks. Hold Messages / Direct to open settings.
//  Keep this file small — heavy method swizzling caused crashes in older builds.
//

import UIKit

@objc public final class IGHooks: NSObject {

    @objc public static let shared = IGHooks()

    private var holdTimer: Timer?
    private var holdingView: UIView?

    @objc public func start() {
        // We rely on gesture recognition rather than deep swizzling
        // for better stability across Instagram updates.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        // Re-attach long-press if needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.attachLongPressIfPossible()
        }
    }

    private func attachLongPressIfPossible() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        // Look for the Messages / Direct area (bottom right-ish)
        // This is intentionally lightweight.
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        gesture.minimumPressDuration = 1.0
        window.addGestureRecognizer(gesture)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        // Simple location check — bottom right quadrant is usually Messages
        let location = gesture.location(in: gesture.view)
        let bounds = gesture.view?.bounds ?? .zero

        if location.y > bounds.height * 0.75 && location.x > bounds.width * 0.6 {
            // Open the appropriate panel
            if GlassPreferences.shared.glossyMode {
                GlassPanelGlossy.shared.present()
            } else {
                GlassPanel.shared.present()
            }

            if GlassPreferences.shared.haptics {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
    }
}
