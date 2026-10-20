//
//  GlassReady.swift
//  GlossyGlass v5
//
//  Simple readiness gate. Waits until a key window and basic UI exist.
//  Critical for Live Container and slow launches.
//

import UIKit

@objc public final class GlassReady: NSObject {

    @objc public static let shared = GlassReady()

    private var isReady = false
    private var callbacks: [() -> Void] = []

    @objc public func waitUntilReady(_ completion: @escaping () -> Void) {
        if isReady {
            completion()
            return
        }

        callbacks.append(completion)
        startPolling()
    }

    private func startPolling() {
        var attempts = 0
        let maxAttempts = 40 // ~20 seconds

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            attempts += 1

            if self.checkReady() || attempts >= maxAttempts {
                timer.invalidate()
                self.isReady = true
                let cbs = self.callbacks
                self.callbacks.removeAll()
                cbs.forEach { $0() }
            }
        }
    }

    private func checkReady() -> Bool {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return false
        }

        // Basic check: window has a root and some depth
        guard let root = window.rootViewController else { return false }
        return root.view.bounds.width > 100 && root.view.subviews.count > 0
    }
}
