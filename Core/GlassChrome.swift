//
//  GlassChrome.swift
//  GlossyGlass v5
//
//  Owns the real chrome. Finds the actual tab bar / nav bar and paints them.
//  No floating window overlays unless absolutely necessary.
//

import UIKit

@objc public final class GlassChrome: NSObject {

    @objc public static let shared = GlassChrome()

    private var started = false
    private var observer: NSObjectProtocol?

    // MARK: - Start

    @objc public func start() {
        guard !started else { return }
        started = true

        apply(reason: "start")

        // Re-apply when preferences change
        observer = NotificationCenter.default.addObserver(
            forName: .glassPreferencesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.apply(reason: "prefs")
        }

        // Light periodic refresh (Instagram reloads chrome often)
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            self?.apply(reason: "timer")
        }
    }

    // MARK: - Apply

    @objc public func apply(reason: String = "apply") {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }

        // Find real chrome
        guard let window = keyWindow() else { return }

        if prefs.styleTabBar {
            if let tabBar = IGLocator.shared.findTabBar(in: window) {
                GlassMaterial.shared.apply(to: tabBar, compact: true)
                // Make sure icons get the glossy treatment if needed
                if prefs.glossyMode {
                    GlassIcons.shared.apply(to: tabBar)
                }
            }
        }

        if prefs.styleNavBar {
            if let navBar = IGLocator.shared.findNavigationBar(in: window) {
                GlassMaterial.shared.apply(to: navBar, compact: false)
            }
        }

        if prefs.styleButtons {
            // Light touch on common button containers
            IGLocator.shared.findButtonContainers(in: window).forEach { view in
                if prefs.glossyMode {
                    GlassIcons.shared.apply(to: view)
                }
            }
        }
    }

    // MARK: - Helpers

    private func keyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
