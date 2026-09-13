import UIKit

/// Single chrome owner for v4 iOS-26 liquid glass presentation layer.
/// Pipeline: event → debounced apply → shield / dock / nav / dm / reels
/// No independent writers. No permanent spam scans.
@objc public final class GlassUICoordinator: NSObject {

    @objc public static let shared = GlassUICoordinator()

    private var started = false
    private var observers: [NSObjectProtocol] = []
    private var lastApply: TimeInterval = 0
    private var pendingWork: DispatchWorkItem?

    private override init() { super.init() }

    // MARK: - Lifecycle

    @objc public func start() {
        DispatchQueue.main.async {
            GlassChromeShield.shared.armEarly()
            GlassInstantShield.arm()
            if !self.started {
                self.started = true
                self.armEvents()
                // Sparse boot pulses only (not a spam timer farm)
                for d in [0.05, 0.35, 1.2, 3.0] as [TimeInterval] {
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
            ) { [weak self] note in
                self?.scheduleApply(reason: note.name.rawValue)
            })
        }
    }

    // MARK: - Apply pipeline

    private func scheduleApply(reason: String) {
        pendingWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.apply(reason: reason)
        }
        pendingWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: work)
    }

    @objc public func apply(reason: String = "apply") {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }

        let now = CFAbsoluteTimeGetCurrent()
        if now - lastApply < 0.10 { return }
        lastApply = now

        // 1) Surface detection
        GlassSurfaceRouter.shared.refresh()
        let surface = GlassSurfaceRouter.shared.activeSurface

        // 2) Claim stock chrome (transparent native fills)
        GlassChromeShield.shared.armEarly()

        // 3) Targeted presentation — only what the surface needs
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

        // Context chrome (profile top actions, search, modals) — light scan
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
    }

    /// Layout-driven paint for a single chrome view (tab/nav only).
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
            } else {
                GlassNavChrome.shared.apply()
            }
        }
    }

    /// Safe mode / reset: tear down all GG overlays.
    @objc public func teardown() {
        for w in GlassAppSupport.allWindows() {
            GlassOverlayRegistry.shared.clearAll(in: w)
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
