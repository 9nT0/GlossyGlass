import UIKit

@objc public final class GlassChrome: NSObject {
    @objc public static let shared = GlassChrome()

    private var started = false
    private var lastApply: TimeInterval = 0

    @objc public func start() {
        guard !started else { return }
        started = true
        apply(reason: "start")

        NotificationCenter.default.addObserver(
            forName: .glassPreferencesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.apply(reason: "prefs")
        }

        Timer.scheduledTimer(withTimeInterval: 1.6, repeats: true) { [weak self] _ in
            self?.apply(reason: "timer")
        }
    }

    @objc public func apply(reason: String = "apply") {
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastApply < 0.22 { return }
        lastApply = now

        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        guard let window = keyWindow() else { return }

        // Tab bar → iOS 26 pill
        if prefs.styleTabBar {
            if let tab = IGLocator.shared.findTabBar(in: window) {
                clearBackgrounds(on: tab)
                // Pill shape
                let h = tab.bounds.height > 0 ? tab.bounds.height : 54
                let corner = min(h * 0.48, 28)
                GlassMaterial.shared.apply(to: tab, style: .pill, corner: corner)
                alignTabItems(in: tab)
                if prefs.glossyMode { GlassIcons.shared.apply(to: tab) }
                if prefs.animations {
                    for sub in tab.subviews where sub is UIControl || sub is UIButton {
                        GlassAnimations.shared.attachPress(to: sub)
                    }
                }
            }
        }

        // Navigation bar
        if prefs.styleNavBar {
            if let nav = IGLocator.shared.findNavigationBar(in: window) {
                clearBackgrounds(on: nav)
                GlassMaterial.shared.apply(to: nav, style: .standard, corner: 0)
            }
        }

        // DMs
        if prefs.styleDMs {
            GlassDMChrome.shared.apply(in: window)
        }

        // Reels / Stories
        if prefs.styleReels {
            GlassReelsChrome.shared.apply(in: window)
        }

        // Profiles
        if prefs.styleProfiles {
            GlassProfileChrome.shared.apply(in: window)
        }

        // Generic buttons
        if prefs.styleButtons {
            for c in IGLocator.shared.findButtonContainers(in: window) {
                if prefs.glossyMode { GlassIcons.shared.apply(to: c) }
                if prefs.animations { GlassAnimations.shared.attachPress(to: c) }
            }
        }
    }

    /// Keep tab bar items evenly spaced inside the pill
    private func alignTabItems(in tab: UIView) {
        // Soft layout pass — Instagram often uses stack or custom layout
        tab.layoutIfNeeded()
        for sub in tab.subviews {
            if sub is UIControl || NSStringFromClass(type(of: sub)).lowercased().contains("tab") {
                sub.contentMode = .center
            }
        }
    }

    private func clearBackgrounds(on view: UIView) {
        view.backgroundColor = .clear
        for sub in view.subviews {
            let n = NSStringFromClass(type(of: sub)).lowercased()
            if n.contains("background") || n.contains("blur") || n.contains("effect") {
                if sub.tag == 0x4747_4546 || sub.tag == 0x4747_5249 || sub.tag == 0x4747_474C { continue }
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
