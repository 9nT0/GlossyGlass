import UIKit

@objc public final class GlassChrome: NSObject {
    @objc public static let shared = GlassChrome()
    private var started = false
    private var last: TimeInterval = 0

    @objc public func start() {
        guard !started else { return }
        started = true
        apply(reason: "start")
        NotificationCenter.default.addObserver(forName: .glassPreferencesDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.apply(reason: "prefs")
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self?.apply(reason: "active") }
        }
        Timer.scheduledTimer(withTimeInterval: 0.85, repeats: true) { [weak self] _ in
            self?.apply(reason: "timer")
        }
    }

    @objc public func apply(reason: String = "apply") {
        let now = CFAbsoluteTimeGetCurrent()
        if now - last < 0.12 { return }
        last = now
        let p = GlassPreferences.shared
        guard p.isEnabled, !p.safeMode else { return }
        let windows = GlassAppSupport.allWindows()
        guard !windows.isEmpty else { return }
        for window in windows { applyToWindow(window, prefs: p) }
    }

    private func applyToWindow(_ window: UIWindow, prefs p: GlassPreferences) {
        if p.styleTabBar, let tab = IGLocator.shared.findTabBar(in: window) {
            installPill(on: tab, prefs: p)
            if p.glossyMode { GlassIcons.shared.apply(to: tab) }
            if p.animations {
                for s in tab.subviews where s is UIControl || s is UIButton {
                    GlassAnimations.shared.attachPress(to: s)
                }
            }
        }

        if p.styleNavBar, let nav = IGLocator.shared.findNavigationBar(in: window) {
            guard !IGLocator.shared.isContent(nav) else { return }
            nav.backgroundColor = .clear
            if let bar = nav as? UINavigationBar {
                bar.isTranslucent = true
                bar.setBackgroundImage(UIImage(), for: .default)
                bar.shadowImage = UIImage()
            }
            for sub in nav.subviews {
                let n = NSStringFromClass(type(of: sub)).lowercased()
                if n.contains("background") || n.contains("visualeffect") || n.contains("barbackground") {
                    sub.backgroundColor = .clear
                    sub.isOpaque = false
                }
            }
            GlassMaterial.shared.apply(to: nav, style: p.glossyMode ? .strong : .standard, corner: 0)
            for sub in nav.subviews {
                if (sub is UIControl || sub is UIButton) && sub.bounds.height > 20 && sub.bounds.height < 52 {
                    if p.animations { GlassAnimations.shared.attachPress(to: sub) }
                }
            }
        }

        if p.styleDMs {
            for c in IGLocator.shared.findComposers(in: window) {
                guard c.bounds.height > 34, c.bounds.height < 100 else { continue }
                guard !IGLocator.shared.isContent(c) else { continue }
                GlassMaterial.shared.apply(to: c, style: .soft, corner: 20)
                if p.animations { GlassAnimations.shared.attachPress(to: c) }
            }
            for btn in IGLocator.shared.findCallButtons(in: window) {
                GlassMaterial.shared.applyCircle(to: btn)
                if p.animations { GlassAnimations.shared.attachPress(to: btn) }
            }
            GlassDMChrome.shared.apply(in: window)
        }

        if p.styleReels { GlassReelsChrome.shared.apply(in: window) }
        if p.styleProfiles { GlassProfileChrome.shared.apply(in: window) }
        if p.styleFeed { GlassFeedChrome.shared.apply(in: window) }
        if p.styleSearch { GlassSearchChrome.shared.apply(in: window) }
        if p.styleContext { GlassContextChrome.shared.apply(in: window) }

        if p.styleButtons {
            for c in IGLocator.shared.findButtonContainers(in: window) {
                guard !IGLocator.shared.isContent(c) else { continue }
                if p.glossyMode { GlassIcons.shared.apply(to: c) }
                if p.animations { GlassAnimations.shared.attachPress(to: c) }
            }
        }
    }

    private func installPill(on tab: UIView, prefs p: GlassPreferences) {
        tab.backgroundColor = .clear
        tab.isOpaque = false
        for sub in tab.subviews {
            let n = NSStringFromClass(type(of: sub)).lowercased()
            if n.contains("background") || n.contains("blur") || n.contains("effect") || n.contains("visual") {
                if sub.tag == 0x4747_504C { continue }
                sub.backgroundColor = .clear
                sub.isOpaque = false
            }
        }
        let pillTag = 0x4747_504C
        var plate = tab.viewWithTag(pillTag)
        if plate == nil {
            plate = UIView()
            plate!.tag = pillTag
            plate!.isUserInteractionEnabled = false
            plate!.translatesAutoresizingMaskIntoConstraints = false
            tab.insertSubview(plate!, at: 0)
            NSLayoutConstraint.activate([
                plate!.leadingAnchor.constraint(equalTo: tab.leadingAnchor, constant: 10),
                plate!.trailingAnchor.constraint(equalTo: tab.trailingAnchor, constant: -10),
                plate!.topAnchor.constraint(equalTo: tab.topAnchor, constant: 5),
                plate!.bottomAnchor.constraint(equalTo: tab.bottomAnchor, constant: -5)
            ])
        }
        let h = max(tab.bounds.height - 10, 48)
        let corner = min(h * 0.5, 26)
        GlassMaterial.shared.apply(to: plate!, style: .pill, corner: corner)
    }
}
