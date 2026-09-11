import UIKit

/// Sole visual chrome owner. Event-driven. No competing scanners/timers.
@objc public final class GlassChromeCoordinator: NSObject {

    @objc public static let shared = GlassChromeCoordinator()

    private var started = false
    private var observers: [NSObjectProtocol] = []
    private var lastApply: TimeInterval = 0
    private var bootDone = false

    private override init() { super.init() }

    @objc public func start() {
        DispatchQueue.main.async {
            GlassInstantShield.arm()
            if !self.started {
                self.started = true
                self.armEvents()
                // Short startup only
                for d in [0.02, 0.1, 0.3, 0.7] as [TimeInterval] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                        self.apply(reason: "boot")
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    self.bootDone = true
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
            ) { [weak self] _ in
                guard !GlassMutationGate.isSuspended else { return }
                self?.apply(reason: "event")
            })
        }
    }

    @objc public func apply(reason: String = "apply") {
        guard !GlassMutationGate.isSuspended else { return }
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        let now = CFAbsoluteTimeGetCurrent()
        let minGap: TimeInterval = bootDone ? 0.3 : 0.05
        if now - lastApply < minGap { return }
        lastApply = now

        GlassSurfaceRouter.shared.refresh()
        let style = prefs.style
        let intensity = max(prefs.intensity, prefs.exclusiveChrome ? 0.7 : prefs.intensity)
        let opacity = max(prefs.opacity, prefs.exclusiveChrome ? 0.88 : prefs.opacity)

        // Tab dock (Glass-owned frame)
        if prefs.styleTabBar {
            GlassDock.shared.attachIfNeeded()
        }

        // Nav only
        var navs = 0
        var claimed = Set<ObjectIdentifier>()
        for w in GlassAppSupport.allWindows() {
            navs += claimNavs(in: w, depth: 0, style: style, intensity: intensity, opacity: opacity, claimed: &claimed)
        }

        GlassDiagnostics.shared.recordChrome(
            surfaces: (prefs.styleTabBar ? 1 : 0) + navs,
            map: ["tab": prefs.styleTabBar ? 1 : 0, "nav": navs],
            note: "coord:\(reason) n\(navs)"
        )
    }

    @objc public func paintIfChrome(_ view: UIView) {
        guard !GlassMutationGate.isSuspended else { return }
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        let name = NSStringFromClass(type(of: view)).lowercased()
        if view is UITabBar || name.contains("igtabbar") {
            guard prefs.styleTabBar else { return }
            GlassDock.shared.onLayout(view)
        } else if view is UINavigationBar || name.contains("ignavigationbar") {
            guard prefs.styleNavigationBar else { return }
            claimNav(view, style: prefs.style, intensity: prefs.intensity, opacity: prefs.opacity)
        }
    }

    private func claimNav(_ view: UIView, style: String, intensity: CGFloat, opacity: CGFloat) {
        if GlassMediaExclusion.shouldSkipGlass(for: view) { return }
        GlassMaterialEngine.shared.neutralizeStockChrome(view)
        if let nav = view as? UINavigationBar {
            GlassNavigationHelper.applyNavigationBarStyle(to: nav)
        }
        GlassMaterialEngine.shared.install(into: view, style: style, intensity: intensity, opacity: opacity, compact: false)
    }

    private func claimNavs(in view: UIView, depth: Int, style: String, intensity: CGFloat, opacity: CGFloat,
                           claimed: inout Set<ObjectIdentifier>) -> Int {
        guard depth < 12 else { return 0 }
        var n = 0
        let prefs = GlassPreferences.shared
        let id = ObjectIdentifier(view)
        let name = NSStringFromClass(type(of: view)).lowercased()
        if !claimed.contains(id), prefs.styleNavigationBar {
            if view is UINavigationBar || name.contains("ignavigationbar") {
                claimNav(view, style: style, intensity: intensity, opacity: opacity)
                claimed.insert(id); n += 1
            }
        }
        for s in view.subviews {
            n += claimNavs(in: s, depth: depth + 1, style: style, intensity: intensity, opacity: opacity, claimed: &claimed)
        }
        return n
    }
}
