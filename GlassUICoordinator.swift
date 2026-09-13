import UIKit

/// Single chrome owner for v4 iOS-26 liquid glass presentation layer.
@objc public final class GlassUICoordinator: NSObject {

    @objc public static let shared = GlassUICoordinator()

    private var started = false
    private var observers: [NSObjectProtocol] = []
    private var lastApply: TimeInterval = 0

    private override init() { super.init() }

    @objc public func start() {
        DispatchQueue.main.async {
            GlassChromeShield.shared.armEarly()
            GlassInstantShield.arm()
            if !self.started {
                self.started = true
                self.armEvents()
                for d in [0.02, 0.1, 0.25, 0.5, 1.0, 2.0] as [TimeInterval] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                        self.apply(reason: "boot-\(d)")
                    }
                }
            }
            self.apply(reason: "start")
        }
    }

    private func armEvents() {
        guard observers.isEmpty else { return }
        let names: [Notification.Name] = [
            UIApplication.didBecomeActiveNotification,
            UIScene.didActivateNotification,
            UIScene.willEnterForegroundNotification,
            .glassPreferencesDidChange
        ]
        for n in names {
            observers.append(NotificationCenter.default.addObserver(
                forName: n, object: nil, queue: .main
            ) { [weak self] _ in self?.apply(reason: "event") })
        }
    }

    @objc public func apply(reason: String = "apply") {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastApply < 0.12 { return }
        lastApply = now

        GlassSurfaceRouter.shared.refresh()
        GlassChromeShield.shared.armEarly()

        if prefs.styleTabBar {
            GlassDock.shared.attachIfNeeded()
        }
        if prefs.styleNavigationBar {
            GlassNavChrome.shared.apply()
        }
        GlassDMChrome.shared.apply()
        GlassContextChrome.shared.scan()

        let surface = GlassSurfaceRouter.shared.activeSurfaceName
        GlassDiagnostics.shared.recordChrome(
            surfaces: 1,
            map: ["dock": prefs.styleTabBar ? 1 : 0, "nav": prefs.styleNavigationBar ? 1 : 0],
            note: "ui:\(reason) surface:\(surface)"
        )
    }

    @objc public func paintIfChrome(_ view: UIView) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if view is UITabBar || n.contains("igtabbar") {
            guard prefs.styleTabBar else { return }
            GlassDock.shared.onLayout(view)
        } else if view is UINavigationBar || n.contains("ignavigationbar") {
            guard prefs.styleNavigationBar else { return }
            if let nav = view as? UINavigationBar {
                GlassNavChrome.shared.apply(to: nav)
            }
        }
    }
}

// Compatibility aliases so old call sites keep working
@objc public final class GlassChromeCoordinator: NSObject {
    @objc public static let shared = GlassChromeCoordinator()
    @objc public func start() { GlassUICoordinator.shared.start() }
    @objc public func apply(reason: String = "apply") { GlassUICoordinator.shared.apply(reason: reason) }
    @objc public func paintIfChrome(_ view: UIView) { GlassUICoordinator.shared.paintIfChrome(view) }
}
