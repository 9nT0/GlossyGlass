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
        Timer.scheduledTimer(withTimeInterval: 1.4, repeats: true) { [weak self] _ in
            self?.apply(reason: "timer")
        }
    }

    @objc public func apply(reason: String = "apply") {
        let now = CFAbsoluteTimeGetCurrent()
        if now - last < 0.18 { return }
        last = now
        let p = GlassPreferences.shared
        guard p.isEnabled, !p.safeMode, let window = keyWindow() else { return }

        if p.styleTabBar, let tab = IGLocator.shared.findTabBar(in: window) {
            clearBG(tab)
            let h = tab.bounds.height > 10 ? tab.bounds.height : 52
            GlassMaterial.shared.apply(to: tab, style: .pill, corner: min(h * 0.5, 26))
            if p.glossyMode { GlassIcons.shared.apply(to: tab) }
            if p.animations {
                for s in tab.subviews where s is UIControl || s is UIButton {
                    GlassAnimations.shared.attachPress(to: s)
                }
            }
        }

        if p.styleNavBar, let nav = IGLocator.shared.findNavigationBar(in: window) {
            clearBG(nav)
            GlassMaterial.shared.apply(to: nav, style: .standard, corner: 0)
        }

        if p.styleDMs { GlassDMChrome.shared.apply(in: window) }
        if p.styleReels { GlassReelsChrome.shared.apply(in: window) }
        if p.styleProfiles { GlassProfileChrome.shared.apply(in: window) }
        if p.styleFeed { GlassFeedChrome.shared.apply(in: window) }
        if p.styleSearch { GlassSearchChrome.shared.apply(in: window) }
        if p.styleContext { GlassContextChrome.shared.apply(in: window) }

        if p.styleButtons {
            for c in IGLocator.shared.findButtonContainers(in: window) {
                if p.glossyMode { GlassIcons.shared.apply(to: c) }
                if p.animations { GlassAnimations.shared.attachPress(to: c) }
            }
        }
    }

    private func clearBG(_ view: UIView) {
        view.backgroundColor = .clear
        view.isOpaque = false
        let keep: Set<Int> = [0x4747_4546, 0x4747_5249, 0x4747_474C, 0x4747_424C, 0x4747_544E]
        for sub in view.subviews {
            let n = NSStringFromClass(type(of: sub)).lowercased()
            if (n.contains("background") || n.contains("blur") || n.contains("effect") || n.contains("visual")) && !keep.contains(sub.tag) {
                sub.backgroundColor = .clear
                sub.isOpaque = false
            }
        }
    }

    private func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
