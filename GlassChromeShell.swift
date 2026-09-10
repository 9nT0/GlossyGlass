import UIKit

/// Owns Instagram chrome: strip stock fills, install visible GG glass on real bars only.
@objc public final class GlassChromeShell: NSObject {

    @objc public static let shared = GlassChromeShell()

    private var timer: Timer?
    private var observer: NSObjectProtocol?
    private var lastPass: TimeInterval = 0
    private(set) var chromeAttached = false
    private(set) var surfacesApplied: [String: Int] = [:]
    private let materialTag = 0x4747_4D41
    private let tintTag = 0x4747_544E

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
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
                self?.reassert()
            }
            for d in [0.4, 1.0, 2.0, 4.0, 8.0] as [TimeInterval] {
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
        if now - lastPass < 0.25 { return }
        lastPass = now

        GlassSurfaceRouter.shared.refresh()
        let surface = GlassSurfaceRouter.shared.activeSurface
        var applied = 0
        surfacesApplied.removeAll()

        // Only high-quality host hits — never inner content views
        let hits = GlassLocator.shared.scanChromeHosts().filter { isClaimableHost($0) }
        var claimedIDs = Set<ObjectIdentifier>()

        for hit in hits.prefix(10) {
            let id = ObjectIdentifier(hit.view)
            guard !claimedIDs.contains(id) else { continue }
            // Prefer outermost bar — skip if superview already claimed as same role
            if let parent = hit.view.superview, claimedIDs.contains(ObjectIdentifier(parent)) {
                continue
            }
            let role = roleFor(hit)
            if role == .tab && !prefs.styleTabBar { continue }
            if (role == .nav || role == .header) && !prefs.styleNavigationBar { continue }

            stripAndGlass(hit.view, role: role, surface: surface)
            claimedIDs.insert(id)
            applied += 1
            surfacesApplied[hit.kind, default: 0] += 1
        }

        // Walk for plain UITabBar / UINavigationBar not in locator list
        for window in GlassAppSupport.allWindows() {
            applied += claimUIKitBars(in: window, depth: 0, surface: surface, claimed: &claimedIDs)
        }

        chromeAttached = applied > 0
        GlassDiagnostics.shared.recordChrome(
            surfaces: applied,
            map: surfacesApplied,
            note: applied > 0 ? "Chrome claimed visible" : "No claimable hosts"
        )
    }

    private func isClaimableHost(_ hit: GlassLocator.HostHit) -> Bool {
        let name = NSStringFromClass(type(of: hit.view))
        let lower = name.lowercased()
        // NEVER claim inner content / layout helpers
        let banned = [
            "contentview", "buttonbar", "stackview", "layoutguide",
            "visualeffect", "transitionview", "wrapper", "backgroundview",
            "modernbar", "platter", "shadow", "label", "imageview",
            "uibutton", "uicontrol", "scrollview"
        ]
        if banned.contains(where: { lower.contains($0) }) { return false }
        // Prefer real bars
        if hit.view is UITabBar || hit.view is UINavigationBar { return true }
        if lower.contains("igtabbar") || lower.contains("ignavigationbar") { return true }
        if hit.kind.hasPrefix("NameTab") || hit.kind.hasPrefix("NameNav") { return true }
        if hit.kind.hasPrefix("GeoBottom") || hit.kind.hasPrefix("AXTab") { return true }
        if hit.kind.hasPrefix("UINavigationBar") || hit.kind.hasPrefix("UITabBar") { return true }
        // Skip low-score noise
        return hit.score >= 70
    }

    private func roleFor(_ hit: GlassLocator.HostHit) -> GlassChromeRole {
        if hit.view is UITabBar { return .tab }
        if hit.view is UINavigationBar { return .nav }
        let k = hit.kind.lowercased()
        if k.contains("tab") || k.contains("bottom") { return .tab }
        if k.contains("nav") || k.contains("header") || k.contains("top") { return .nav }
        // Geometry fallback
        if let win = hit.view.window {
            let f = hit.view.convert(hit.view.bounds, to: nil)
            if f.maxY > win.bounds.height - 120 { return .tab }
        }
        return .header
    }

    private func claimUIKitBars(in view: UIView, depth: Int, surface: GlassSurfaceKind, claimed: inout Set<ObjectIdentifier>) -> Int {
        guard depth < 16 else { return 0 }
        var n = 0
        let prefs = GlassPreferences.shared
        let id = ObjectIdentifier(view)
        if !claimed.contains(id) {
            if let tab = view as? UITabBar, prefs.styleTabBar {
                stripAndGlass(tab, role: .tab, surface: surface)
                claimed.insert(id)
                n += 1
                surfacesApplied["UITabBar", default: 0] += 1
            } else if let nav = view as? UINavigationBar, prefs.styleNavigationBar {
                stripAndGlass(nav, role: .nav, surface: surface)
                claimed.insert(id)
                n += 1
                surfacesApplied["UINavigationBar", default: 0] += 1
            }
        }
        for s in view.subviews {
            n += claimUIKitBars(in: s, depth: depth + 1, surface: surface, claimed: &claimed)
        }
        return n
    }

    private func stripAndGlass(_ view: UIView, role: GlassChromeRole, surface: GlassSurfaceKind) {
        let prefs = GlassPreferences.shared
        let exclusive = prefs.exclusiveChrome
        let recipe = GlassSurfaceRouter.shared.recipe(for: surface, role: role)
        let isDark = view.traitCollection.userInterfaceStyle == .dark
            || prefs.style.lowercased() != "clear" // IG is usually dark chrome

        // --- HARD STRIP ---
        view.backgroundColor = .clear
        view.layer.backgroundColor = UIColor.clear.cgColor
        view.layer.borderWidth = 0
        view.layer.shadowOpacity = 0

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
            tab.barStyle = .black
        }
        if let nav = view as? UINavigationBar {
            let a = UINavigationBarAppearance()
            a.configureWithTransparentBackground()
            a.backgroundEffect = nil
            a.backgroundColor = .clear
            a.shadowColor = .clear
            a.shadowImage = UIImage()
            nav.standardAppearance = a
            nav.scrollEdgeAppearance = a
            nav.compactAppearance = a
            if #available(iOS 15.0, *) {
                nav.compactScrollEdgeAppearance = a
            }
            nav.isTranslucent = true
            nav.barTintColor = .clear
            nav.backgroundColor = .clear
            nav.setBackgroundImage(UIImage(), for: .default)
            nav.shadowImage = UIImage()
        }

        if exclusive {
            for sub in view.subviews {
                let sn = NSStringFromClass(type(of: sub)).lowercased()
                if sub.tag == materialTag || sub.tag == tintTag { continue }
                // Remove stock background plates
                if sub is UIVisualEffectView {
                    (sub as? UIVisualEffectView)?.removeFromSuperview()
                    continue
                }
                if sn.contains("background") || sn.contains("barbackground") || sn.contains("_uibar") {
                    sub.backgroundColor = .clear
                    sub.isHidden = false
                    sub.alpha = 1
                    // clear but keep for layout
                }
            }
        }

        // --- VISIBLE MATERIAL (must be obvious) ---
        let effect = recipe.blurEffect(dark: true) // IG chrome is dark-first
        let blur: UIVisualEffectView
        if let existing = view.viewWithTag(materialTag) as? UIVisualEffectView {
            blur = existing
            blur.effect = effect
        } else {
            blur = UIVisualEffectView(effect: effect)
            blur.tag = materialTag
            blur.isUserInteractionEnabled = false
            blur.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(blur, at: 0)
            NSLayoutConstraint.activate([
                blur.topAnchor.constraint(equalTo: view.topAnchor),
                blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                blur.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        // Boost visibility: never nearly-invisible
        blur.alpha = max(0.82, min(1.0, recipe.opacity))

        // Tint plate so glass reads on pure black IG bars
        let tint: UIView
        if let existing = view.viewWithTag(tintTag) {
            tint = existing
        } else {
            tint = UIView()
            tint.tag = tintTag
            tint.isUserInteractionEnabled = false
            tint.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(tint, at: 1)
            NSLayoutConstraint.activate([
                tint.topAnchor.constraint(equalTo: view.topAnchor),
                tint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tint.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        let baseAlpha: CGFloat
        switch recipe.style.lowercased() {
        case "clear": baseAlpha = 0.28
        case "tinted": baseAlpha = 0.45
        case "liquid", "heavy": baseAlpha = 0.38
        default: baseAlpha = 0.35 // frosted
        }
        tint.backgroundColor = UIColor.white.withAlphaComponent(baseAlpha * recipe.intensity)

        if role == .tab {
            GlassPrivateBridge.setContinuousCorners(view, radius: 0) // full width, no pill box
        }
    }
}

@objc public enum GlassChromeRole: Int {
    case nav = 0
    case tab = 1
    case header = 2
}
