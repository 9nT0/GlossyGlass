import UIKit

/// Single owner of visual chrome. Event-driven. No 0.1s destroy/rebuild loops.
///
/// STARTUP → detect → neutralize → install material → observe → repair only when replaced
@objc public final class GlassChromeCoordinator: NSObject {

    @objc public static let shared = GlassChromeCoordinator()

    private var started = false
    private var observers: [NSObjectProtocol] = []
    private var lastApply: TimeInterval = 0
    private var bootDone = false

    private override init() { super.init() }

    @objc public func start() {
        DispatchQueue.main.async {
            if !self.started {
                self.started = true
                self.armEvents()
                // Short startup guard only (not permanent architecture)
                for d in [0.02, 0.12, 0.35, 0.8, 1.6] as [TimeInterval] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                        self.apply(reason: "boot")
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.bootDone = true
                }
            }
            GlassContextChrome.shared.start()
            GlassInstantsChrome.shared.start()
            self.apply(reason: "start")
        }
    }

    private func armEvents() {
        guard observers.isEmpty else { return }
        let names: [Notification.Name] = [
            UIApplication.didBecomeActiveNotification,
            UIApplication.didFinishLaunchingNotification,
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
        // During boot allow denser applies; after boot calm
        let minGap: TimeInterval = bootDone ? 0.25 : 0.06
        if now - lastApply < minGap { return }
        lastApply = now

        GlassSurfaceRouter.shared.refresh()
        let surface = GlassSurfaceRouter.shared.activeSurface
        let style = prefs.style
        let intensity = max(prefs.intensity, prefs.exclusiveChrome ? 0.7 : prefs.intensity)
        let opacity = max(prefs.opacity, prefs.exclusiveChrome ? 0.88 : prefs.opacity)

        var tabs = 0, navs = 0
        var claimed = Set<ObjectIdentifier>()

        for hit in GlassLocator.shared.scanChromeHosts() {
            guard isChromeHost(hit) else { continue }
            let id = ObjectIdentifier(hit.view)
            guard !claimed.contains(id) else { continue }
            let role = role(for: hit)
            if role == .tab && prefs.styleTabBar {
                claimTab(hit.view, style: style, intensity: intensity, opacity: opacity)
                claimed.insert(id); tabs += 1
            } else if (role == .nav || role == .header) && prefs.styleNavigationBar {
                claimNav(hit.view, style: style, intensity: intensity, opacity: opacity)
                claimed.insert(id); navs += 1
            }
        }

        // UIKit fallbacks
        for w in GlassAppSupport.allWindows() {
            walk(w, depth: 0, style: style, intensity: intensity, opacity: opacity, claimed: &claimed, tabs: &tabs, navs: &navs)
        }

        GlassDiagnostics.shared.recordChrome(
            surfaces: tabs + navs,
            map: ["tab": tabs, "nav": navs, "surface": 0],
            note: "coord:\(reason) t\(tabs)/n\(navs) \(GlassSurfaceRouter.shared.activeSurfaceName)"
        )
    }

    @objc public func paintIfChrome(_ view: UIView) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        let name = NSStringFromClass(type(of: view)).lowercased()
        let style = prefs.style
        let intensity = max(prefs.intensity, prefs.exclusiveChrome ? 0.7 : prefs.intensity)
        let opacity = max(prefs.opacity, prefs.exclusiveChrome ? 0.88 : prefs.opacity)
        if view is UITabBar || name.contains("igtabbar") {
            guard prefs.styleTabBar else { return }
            claimTab(view, style: style, intensity: intensity, opacity: opacity)
        } else if view is UINavigationBar || name.contains("ignavigationbar") {
            guard prefs.styleNavigationBar else { return }
            claimNav(view, style: style, intensity: intensity, opacity: opacity)
        }
    }

    private func claimTab(_ view: UIView, style: String, intensity: CGFloat, opacity: CGFloat) {
        GlassMaterialEngine.shared.neutralizeStockChrome(view)
        if let tab = view as? UITabBar {
            GlassNavigationHelper.applyTabBarStyle(to: tab)
        }
        GlassMaterialEngine.shared.install(into: view, style: style, intensity: intensity, opacity: opacity, compact: true)
        // Selected lens
        if let tab = view as? UITabBar, let items = tab.items, let sel = tab.selectedItem,
           let idx = items.firstIndex(of: sel) {
            GlassMaterialEngine.shared.updateSelectedLens(in: view, index: idx, count: items.count)
        } else {
            GlassMaterialEngine.shared.updateSelectedLens(in: view, index: 0, count: 5)
        }
    }

    private func claimNav(_ view: UIView, style: String, intensity: CGFloat, opacity: CGFloat) {
        GlassMaterialEngine.shared.neutralizeStockChrome(view)
        if let nav = view as? UINavigationBar {
            GlassNavigationHelper.applyNavigationBarStyle(to: nav)
        }
        GlassMaterialEngine.shared.install(into: view, style: style, intensity: intensity, opacity: opacity, compact: false)
    }

    private func walk(_ view: UIView, depth: Int, style: String, intensity: CGFloat, opacity: CGFloat,
                      claimed: inout Set<ObjectIdentifier>, tabs: inout Int, navs: inout Int) {
        guard depth < 12 else { return }
        let prefs = GlassPreferences.shared
        let id = ObjectIdentifier(view)
        let name = NSStringFromClass(type(of: view)).lowercased()
        if !claimed.contains(id) {
            if (view is UITabBar || name.contains("igtabbar")) && prefs.styleTabBar {
                claimTab(view, style: style, intensity: intensity, opacity: opacity)
                claimed.insert(id); tabs += 1
            } else if (view is UINavigationBar || name.contains("ignavigationbar")) && prefs.styleNavigationBar {
                claimNav(view, style: style, intensity: intensity, opacity: opacity)
                claimed.insert(id); navs += 1
            }
        }
        for s in view.subviews {
            walk(s, depth: depth + 1, style: style, intensity: intensity, opacity: opacity, claimed: &claimed, tabs: &tabs, navs: &navs)
        }
    }

    private func isChromeHost(_ hit: GlassLocator.HostHit) -> Bool {
        let lower = NSStringFromClass(type(of: hit.view)).lowercased()
        let banned = ["contentview", "buttonbar", "stackview", "collection", "swipe",
                      "scrollview", "label", "imageview", "transition", "visualeffect",
                      "searchbar", "prompt", "titleview"]
        if banned.contains(where: { lower.contains($0) }) { return false }
        // Strict: only real bars — GeoTop caused DM name overlays
        if hit.view is UITabBar || hit.view is UINavigationBar { return true }
        if lower.contains("igtabbar") || lower.contains("ignavigationbar") { return true }
        if hit.kind.hasPrefix("NameTab:") || hit.kind.hasPrefix("NameNav:IG") { return true }
        if hit.kind.hasPrefix("UITabBar") || hit.kind.hasPrefix("UINavigationBar") { return true }
        if hit.kind.hasPrefix("AXTab") && hit.score >= 75 { return true }
        return false
    }

    private func role(for hit: GlassLocator.HostHit) -> GlassChromeRole {
        if hit.view is UITabBar { return .tab }
        if hit.view is UINavigationBar { return .nav }
        let k = hit.kind.lowercased()
        if k.contains("tab") || k.contains("bottom") { return .tab }
        return .nav
    }
}
