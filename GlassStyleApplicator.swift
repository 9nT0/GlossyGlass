import UIKit

/// Applies nav/tab chrome. Buttons/cards are opt-in and conservative (won't nuke Follow).
@objc public class GlassStyleApplicator: NSObject {

    private static var started = false
    private static var timer: Timer?

    @objc public static func start() {
        guard !started else {
            applyAll()
            return
        }
        started = true
        applyAll()
        NotificationCenter.default.addObserver(
            forName: .glassPreferencesDidChange,
            object: nil,
            queue: .main
        ) { _ in applyAll() }
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            applyAll()
        }
    }

    @objc public static func applyAll() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }

        for window in GlassAppSupport.allWindows() {
            walk(window, depth: 0)
        }
    }

    private static func walk(_ view: UIView, depth: Int) {
        if depth > 12 { return }
        let prefs = GlassPreferences.shared

        if prefs.styleNavigationBar, let nav = view as? UINavigationBar {
            GlassNavigationHelper.applyNavigationBarStyle(to: nav)
        }
        if prefs.styleTabBar, let tab = view as? UITabBar {
            GlassNavigationHelper.applyTabBarStyle(to: tab)
        }

        // Only style our own Glass button, never random Follow/CTA
        if view is GlassSettingsButton {
            // already self-styled
        }

        if prefs.styleCards {
            applyCardIfLikely(view)
        }

        for s in view.subviews {
            walk(s, depth: depth + 1)
        }
    }

    private static func applyCardIfLikely(_ view: UIView) {
        // Only views that already look like cards (existing corner radius)
        guard view.layer.cornerRadius >= 10 else { return }
        guard view.bounds.width > 120, view.bounds.height > 40, view.bounds.height < 400 else { return }
        // Skip controls
        if view is UIControl || view is UIButton { return }
        view.layer.cornerCurve = .continuous
        let isDark = view.traitCollection.userInterfaceStyle == .dark
        if view.layer.borderWidth < 0.15 {
            view.layer.borderWidth = 0.4
            view.layer.borderColor = UIColor.white.withAlphaComponent(isDark ? 0.10 : 0.18).cgColor
        }
    }
}
