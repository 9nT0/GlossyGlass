import UIKit

/// Single chrome owner — debounced, sparse retries, no thrash.
@objc public final class GlassUICoordinator: NSObject {

    @objc public static let shared = GlassUICoordinator()

    private var started = false
    private var lastApply: TimeInterval = 0
    private var observers: [NSObjectProtocol] = []
    private var pendingWorkItem: DispatchWorkItem?

    private override init() { super.init() }

    @objc public func start() {
        DispatchQueue.main.async {
            guard !self.started else {
                self.scheduleApply(reason: "start-reentry", delay: 0.15)
                return
            }
            self.started = true
            _ = GlassPreferences.shared
            GlassChromeShield.shared.armEarly()
            GlassContextChrome.shared.start()
            self.installObservers()
            self.apply(reason: "start")
            // Sparse, non-overlapping retries
            for d in [0.6, 2.0, 5.0, 12.0] as [TimeInterval] {
                DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                    self.apply(reason: "delayed-\(d)")
                }
            }
            NSLog("[GlossyGlass] UICoordinator started v4.0.0")
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
                self?.scheduleApply(reason: name.rawValue, delay: 0.2)
            }
            observers.append(o)
        }
        let pref = NotificationCenter.default.addObserver(
            forName: .glassPreferencesDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.scheduleApply(reason: "prefs", delay: 0.1)
        }
        observers.append(pref)
    }

    /// Coalesce rapid apply calls into one.
    private func scheduleApply(reason: String, delay: TimeInterval) {
        pendingWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.apply(reason: reason)
        }
        pendingWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    @objc public func apply(reason: String = "apply") {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled else { return }
        if prefs.safeMode {
            teardown()
            return
        }

        let now = CFAbsoluteTimeGetCurrent()
        if now - lastApply < 0.12 { return }
        lastApply = now

        GlassSurfaceRouter.shared.refresh()
        let surface = GlassSurfaceRouter.shared.activeSurface

        GlassChromeShield.shared.armEarly()

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

        // Context scan less often — every other apply
        if reason == "start" || reason.hasPrefix("delayed") || reason == "prefs" {
            GlassContextChrome.shared.scan()
        }

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
            w.viewWithTag(0x4747_5748)?.removeFromSuperview()
        }
    }
}

@objc public final class GlassChromeCoordinator: NSObject {
    @objc public static let shared = GlassChromeCoordinator()
    @objc public func start() { GlassUICoordinator.shared.start() }
    @objc public func apply(reason: String = "apply") { GlassUICoordinator.shared.apply(reason: reason) }
    @objc public func paintIfChrome(_ view: UIView) { GlassUICoordinator.shared.paintIfChrome(view) }
}
