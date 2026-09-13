import UIKit

/// Single chrome owner. All glass presentation routes through here.
@objc public final class GlassUICoordinator: NSObject {

    @objc public static let shared = GlassUICoordinator()

    private var started = false
    private var lastApply: TimeInterval = 0
    private var observers: [NSObjectProtocol] = []

    private override init() { super.init() }

    @objc public func start() {
        DispatchQueue.main.async {
            guard !self.started else {
                self.apply(reason: "start-reentry")
                return
            }
            self.started = true
            GlassChromeShield.shared.armEarly()
            GlassContextChrome.shared.start()
            self.installObservers()
            self.apply(reason: "start")
            // Extra delayed attaches — IG tab bar often appears late
            for d in [0.4, 1.2, 3.0, 7.0] as [TimeInterval] {
                DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                    self.apply(reason: "delayed-\(d)")
                }
            }
            NSLog("[GlossyGlass] UICoordinator started")
        }
    }

    private func installObservers() {
        let names: [Notification.Name] = [
            UIApplication.didBecomeActiveNotification,
            UIApplication.willEnterForegroundNotification,
            UIScene.didActivateNotification
        ]
        for name in names {
            let o = NotificationCenter.default.addObserver(
                forName: name, object: nil, queue: .main
            ) { [weak self] _ in
                self?.apply(reason: name.rawValue)
            }
            observers.append(o)
        }
        let pref = NotificationCenter.default.addObserver(
            forName: .glassPreferencesDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.apply(reason: "prefs")
        }
        observers.append(pref)
    }

    @objc public func apply(reason: String = "apply") {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled else {
            NSLog("[GlossyGlass] Coordinator apply skipped — disabled")
            return
        }
        if prefs.safeMode {
            teardown()
            return
        }

        let now = CFAbsoluteTimeGetCurrent()
        // Allow faster re-apply on start/delayed
        let minGap: TimeInterval = reason.hasPrefix("delayed") || reason == "start" ? 0.05 : 0.18
        if now - lastApply < minGap { return }
        lastApply = now

        GlassSurfaceRouter.shared.refresh()
        let surface = GlassSurfaceRouter.shared.activeSurface

        GlassChromeShield.shared.armEarly()

        // Always try dock + nav when prefs allow
        if prefs.styleTabBar {
            GlassDock.shared.attachIfNeeded()
        }
        if prefs.styleNavigationBar {
            GlassNavChrome.shared.apply()
        }

        switch surface {
        case .messages:
            GlassDMChrome.shared.apply()
        case .reels:
            GlassReelsChrome.shared.apply()
        default:
            break
        }

        GlassContextChrome.shared.scan()

        GlassDiagnostics.shared.recordChrome(
            surfaces: 1,
            map: [
                "dock": prefs.styleTabBar ? 1 : 0,
                "nav": prefs.styleNavigationBar ? 1 : 0,
                "reels": surface == .reels ? 1 : 0,
                "dm": surface == .messages ? 1 : 0
            ],
            note: "ui:\(reason) surface:\(surface.key)"
        )
        NSLog("[GlossyGlass] Coordinator apply reason=%@ surface=%@", reason, surface.key)
    }

    @objc public func paintIfChrome(_ view: UIView) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if view is UITabBar || n.contains("igtabbar") || n.contains("tabbar") {
            guard prefs.styleTabBar else { return }
            GlassDock.shared.onLayout(view)
        } else if view is UINavigationBar || n.contains("ignavigationbar") || n.contains("navigationbar") {
            guard prefs.styleNavigationBar else { return }
            if let nav = view as? UINavigationBar {
                GlassNavChrome.shared.apply(to: nav)
            } else {
                GlassNavChrome.shared.apply()
            }
        }
    }

    @objc public func teardown() {
        for w in GlassAppSupport.allWindows() {
            GlassOverlayRegistry.shared.clearAll(in: w)
        }
    }
}

@objc public final class GlassChromeCoordinator: NSObject {
    @objc public static let shared = GlassChromeCoordinator()
    @objc public func start() { GlassUICoordinator.shared.start() }
    @objc public func apply(reason: String = "apply") { GlassUICoordinator.shared.apply(reason: reason) }
    @objc public func paintIfChrome(_ view: UIView) { GlassUICoordinator.shared.paintIfChrome(view) }
}
