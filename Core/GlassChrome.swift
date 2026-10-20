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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { self?.apply(reason: "active") }
        }
        // Catch profile opens from DMs / pushes
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.apply(reason: "fg")
        }
        Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] _ in
            self?.apply(reason: "timer")
        }
    }

    @objc public func apply(reason: String = "apply") {
        let now = CFAbsoluteTimeGetCurrent()
        if now - last < 0.10 { return }
        last = now
        let p = GlassPreferences.shared
        guard p.isEnabled, !p.safeMode else { return }
        let windows = GlassAppSupport.allWindows()
        guard !windows.isEmpty else { return }
        for window in windows { applyToWindow(window, prefs: p) }
    }

    private func applyToWindow(_ window: UIWindow, prefs p: GlassPreferences) {
        // Tab → slim floating pill
        if p.styleTabBar, let tab = IGLocator.shared.findTabBar(in: window) {
            installPill(on: tab, prefs: p)
            if p.glossyMode { GlassIcons.shared.apply(to: tab) }
            if p.animations {
                for s in tab.subviews where s is UIControl || s is UIButton {
                    GlassAnimations.shared.attachPress(to: s)
                }
            }
        }

        // Nav — light liquid strip, no thick borders
        if p.styleNavBar, let nav = IGLocator.shared.findNavigationBar(in: window) {
            guard !IGLocator.shared.isContent(nav) else { /* continue other work */ } else {
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
                GlassMaterial.shared.apply(to: nav, style: .soft, corner: 0)
            }
        }

        if p.styleDMs {
            for c in IGLocator.shared.findComposers(in: window) {
                guard c.bounds.height > 34, c.bounds.height < 100 else { continue }
                guard !IGLocator.shared.isContent(c) else { continue }
                GlassMaterial.shared.apply(to: c, style: .soft, corner: 22)
            }
            for btn in IGLocator.shared.findCallButtons(in: window) {
                GlassMaterial.shared.applyCircle(to: btn)
            }
            GlassDMChrome.shared.apply(in: window)
        }

        // Always try profile + feed (covers profiles opened from DMs)
        if p.styleProfiles { GlassProfileChrome.shared.apply(in: window) }
        if p.styleReels { GlassReelsChrome.shared.apply(in: window) }
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

    /// Slim iOS-26 style floating capsule — NOT full-width fat bar
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
        // Larger side inset → smaller, floating capsule
        let insetH: CGFloat = 28
        let insetV: CGFloat = 8

        if plate == nil {
            plate = UIView()
            plate!.tag = pillTag
            plate!.isUserInteractionEnabled = false
            plate!.translatesAutoresizingMaskIntoConstraints = false
            tab.insertSubview(plate!, at: 0)
            NSLayoutConstraint.activate([
                plate!.leadingAnchor.constraint(equalTo: tab.leadingAnchor, constant: insetH),
                plate!.trailingAnchor.constraint(equalTo: tab.trailingAnchor, constant: -insetH),
                plate!.topAnchor.constraint(equalTo: tab.topAnchor, constant: insetV),
                plate!.bottomAnchor.constraint(equalTo: tab.bottomAnchor, constant: -insetV)
            ])
        }
        // Pill height from constraints; corner = half of typical pill height
        let approxH: CGFloat = max(tab.bounds.height - insetV * 2, 44)
        let corner = min(approxH * 0.5, 22)
        GlassMaterial.shared.apply(to: plate!, style: .pill, corner: corner)
    }
}
