import UIKit

/// Owns Instagram chrome visually: strips stock bar fills and installs
/// GlossyGlass materials as the real background of detected chrome surfaces.
/// Settings button stays separate. Content (feed/posts) stays visible.
@objc public final class GlassChromeShell: NSObject {

    @objc public static let shared = GlassChromeShell()

    private var timer: Timer?
    private var observer: NSObjectProtocol?
    private var lastPass: TimeInterval = 0
    private(set) var chromeAttached = false
    private(set) var surfacesApplied: [String: Int] = [:]
    private var trackedBars = NSHashTable<UIView>.weakObjects()

    private override init() { super.init() }

    @objc public func start() {
        DispatchQueue.main.async {
            if self.observer == nil {
                self.observer = NotificationCenter.default.addObserver(
                    forName: .glassPreferencesDidChange,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in self?.reassert() }
            }
            self.timer?.invalidate()
            // Calm cadence — not thrashing every frame
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { [weak self] _ in
                self?.reassert()
            }
            for d in [0.6, 1.5, 3.0, 6.0, 12.0] as [TimeInterval] {
                DispatchQueue.main.asyncAfter(deadline: .now() + d) { self.reassert() }
            }
            self.reassert()
        }
    }

    @objc public func reassert() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else {
            chromeAttached = false
            return
        }
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastPass < 0.35 { return }
        lastPass = now

        var applied = 0
        surfacesApplied.removeAll()

        GlassSurfaceRouter.shared.refresh()
        let surface = GlassSurfaceRouter.shared.activeSurface

        // Prefer locator hits first (multi-strategy)
        for hit in GlassLocator.shared.scanChromeHosts().prefix(12) {
            let role: GlassChromeRole
            let k = hit.kind.lowercased()
            if k.contains("tab") || k.contains("bottom") { role = .tab }
            else if k.contains("nav") || k.contains("top") || k.contains("header") { role = .header }
            else { role = hit.view is UITabBar ? .tab : (hit.view is UINavigationBar ? .nav : .header) }
            if role == .tab && !GlassPreferences.shared.styleTabBar { continue }
            if (role == .nav || role == .header) && !GlassPreferences.shared.styleNavigationBar { continue }
            stripAndGlass(hit.view, role: role, surface: surface)
            applied += 1
            surfacesApplied[hit.kind, default: 0] += 1
        }

        for window in GlassAppSupport.allWindows() {
            applied += claimChrome(in: window, depth: 0, surface: surface)
        }

        chromeAttached = applied > 0
        if chromeAttached {
            GlassDiagnostics.shared.recordChrome(
                surfaces: applied,
                map: surfacesApplied,
                note: "Chrome claimed"
            )
        }
    }

    /// Walk hierarchy: strip stock fills, install GG material layers on real chrome only.
    @discardableResult
    private func claimChrome(in view: UIView, depth: Int, surface: GlassSurfaceKind) -> Int {
        guard depth < 20 else { return 0 }
        var count = 0
        let prefs = GlassPreferences.shared

        if let nav = view as? UINavigationBar, prefs.styleNavigationBar {
            stripAndGlass(nav, role: .nav, surface: surface)
            count += 1
            surfacesApplied["nav", default: 0] += 1
        }
        if let tab = view as? UITabBar, prefs.styleTabBar {
            stripAndGlass(tab, role: .tab, surface: surface)
            count += 1
            surfacesApplied["tab", default: 0] += 1
        }

        // Custom IG chrome by geometry + name (not every bottom view)
        if shouldClaimCustom(view) {
            let role: GlassChromeRole = isBottomChrome(view) ? .tab : .header
            if role == .tab && prefs.styleTabBar {
                stripAndGlass(view, role: role, surface: surface)
                count += 1
                surfacesApplied["ig_tab", default: 0] += 1
            } else if role == .header && prefs.styleNavigationBar {
                stripAndGlass(view, role: role, surface: surface)
                count += 1
                surfacesApplied["ig_header", default: 0] += 1
            }
        }

        for sub in view.subviews {
            count += claimChrome(in: sub, depth: depth + 1, surface: surface)
        }
        return count
    }

    private func shouldClaimCustom(_ view: UIView) -> Bool {
        if view is UINavigationBar || view is UITabBar { return false }
        if view is UIButton || view is UILabel || view is UIImageView { return false }
        if view is GlassSettingsButton { return false }
        let name = NSStringFromClass(type(of: view)).lowercased()
        let frame = view.convert(view.bounds, to: nil)
        guard let win = view.window else { return false }
        let h = frame.height
        let w = frame.width
        guard w > win.bounds.width * 0.55 else { return false }
        guard h > 36 && h < 100 else { return false }

        let nameHit =
            name.contains("tabbar") || name.contains("igtab") ||
            name.contains("navbar") || name.contains("navigationbar") ||
            name.contains("igheader") || name.contains("headerbar") ||
            name.contains("bottombar") || name.contains("tabcontroller")

        let bottom = frame.maxY > win.bounds.height - 110
        let top = frame.minY < 120

        // Strict: name hit OR (bottom bar-like with multiple controls)
        if nameHit { return true }
        if bottom {
            let controls = view.subviews.filter { $0 is UIControl || $0 is UIButton }.count
            return controls >= 3 && controls <= 7
        }
        if top && name.contains("header") { return true }
        return false
    }

    private func isBottomChrome(_ view: UIView) -> Bool {
        guard let win = view.window else { return false }
        let frame = view.convert(view.bounds, to: nil)
        return frame.maxY > win.bounds.height - 110
    }

    private func stripAndGlass(_ view: UIView, role: GlassChromeRole, surface: GlassSurfaceKind) {
        trackedBars.add(view)
        let exclusive = GlassPreferences.shared.exclusiveChrome

        // 1) Hard strip stock fills / competing effects
        view.backgroundColor = .clear
        view.layer.backgroundColor = UIColor.clear.cgColor
        view.layer.borderWidth = 0
        view.layer.shadowOpacity = 0
        if exclusive {
            // Remove foreign visual effect views (except our tagged material)
            for sub in view.subviews {
                if let ve = sub as? UIVisualEffectView, sub.tag != 0x4747_4D41 {
                    ve.removeFromSuperview()
                }
            }
        }
        if let tab = view as? UITabBar {
            let a = UITabBarAppearance()
            a.configureWithTransparentBackground()
            a.backgroundEffect = nil
            a.backgroundColor = .clear
            a.shadowColor = .clear
            a.shadowImage = UIImage()
            tab.standardAppearance = a
            tab.scrollEdgeAppearance = a
            tab.isTranslucent = true
            tab.barTintColor = .clear
            tab.backgroundImage = UIImage()
            tab.shadowImage = UIImage()
        }
        if let nav = view as? UINavigationBar {
            GlassNavigationHelper.applyNavigationBarStyle(to: nav)
            return
        }

        // 2) Install single material layer (tag-guarded, not a window overlay)
        let tag = 0x4747_4D41 // GGMA material
        let recipe = GlassSurfaceRouter.shared.recipe(for: surface, role: role)
        let isDark = view.traitCollection.userInterfaceStyle == .dark

        if let existing = view.viewWithTag(tag) as? UIVisualEffectView {
            existing.effect = recipe.blurEffect(dark: isDark)
            existing.alpha = recipe.opacity
            return
        }

        let effect = recipe.blurEffect(dark: isDark)
        let blur = UIVisualEffectView(effect: effect)
        blur.tag = tag
        blur.isUserInteractionEnabled = false
        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.alpha = recipe.opacity
        view.insertSubview(blur, at: 0)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Continuous corners only on bottom custom chrome (not full-width nav)
        if role == .tab {
            GlassPrivateBridge.setContinuousCorners(view, radius: min(22, view.bounds.height * 0.35))
        }
        view.layer.borderWidth = 0
        view.layer.shadowOpacity = 0
    }
}

@objc public enum GlassChromeRole: Int {
    case nav = 0
    case tab = 1
    case header = 2
}
