//
//  GlassBootstrap.swift
//  GlossyGlass v5
//
//  Single entry point. Starts the readiness gate then the chrome engine.
//

import UIKit

@objc public final class GlassBootstrap: NSObject {

    private static var started = false

    @objc public static func start() {
        DispatchQueue.main.async {
            guard !started else { return }
            started = true

            NSLog("[GlossyGlass v5] Bootstrap start")

            // Preferences first
            _ = GlassPreferences.shared

            // Wait until the host UI is actually ready
            GlassReady.shared.waitUntilReady {
                NSLog("[GlossyGlass v5] Host ready — applying chrome")
                GlassChrome.shared.start()
                GlassPanel.shared.prepare()
            }
        }
    }
}
