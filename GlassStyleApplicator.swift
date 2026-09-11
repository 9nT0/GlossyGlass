import UIKit

/// Light polish only. Chrome ownership is GlassChromeCoordinator / GlassDock.
@objc public class GlassStyleApplicator: NSObject {

    private static var started = false
    private static var observer: NSObjectProtocol?

    @objc public static func start() {
        DispatchQueue.main.async {
            if !started {
                started = true
                observer = NotificationCenter.default.addObserver(
                    forName: .glassPreferencesDidChange,
                    object: nil,
                    queue: .main
                ) { _ in applyAll() }
                GlassChromeCoordinator.shared.start()
            }
            applyAll()
        }
    }

    @objc public static func applyToViewController(_ vc: UIViewController) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }

        if prefs.styleNavigationBar, let nav = vc.navigationController?.navigationBar {
            GlassNavigationHelper.applyNavigationBarStyle(to: nav)
        }
        if prefs.styleTabBar, let tab = vc.tabBarController?.tabBar {
            GlassNavigationHelper.applyTabBarStyle(to: tab)
        }
        for child in vc.children {
            if let nav = child as? UINavigationController, prefs.styleNavigationBar {
                GlassNavigationHelper.applyNavigationBarStyle(to: nav.navigationBar)
            }
            if let tab = child as? UITabBarController, prefs.styleTabBar {
                GlassNavigationHelper.applyTabBarStyle(to: tab.tabBar)
            }
        }
        if let view = vc.viewIfLoaded {
            walkBarsOnly(view, depth: 0)
        }
    }

    @objc public static func applyToView(_ view: UIView) {
        guard GlassPreferences.shared.isEnabled, !GlassPreferences.shared.safeMode else { return }
        walkBarsOnly(view, depth: 0)
    }

    @objc public static func applyAll() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }

        GlassChromeCoordinator.shared.apply(reason: "styleApplicator")

        for w in GlassAppSupport.allWindows() {
            walkBarsOnly(w, depth: 0)
            if prefs.styleButtons || prefs.styleCards {
                walkPolish(w, depth: 0)
            }
        }
    }

    private static func walkBarsOnly(_ view: UIView, depth: Int) {
        guard depth < 20 else { return }
        if GlassMediaExclusion.shouldSkipGlass(for: view) { return }
        let prefs = GlassPreferences.shared
        if let nav = view as? UINavigationBar, prefs.styleNavigationBar {
            GlassNavigationHelper.applyNavigationBarStyle(to: nav)
        }
        if let tab = view as? UITabBar, prefs.styleTabBar {
            GlassNavigationHelper.applyTabBarStyle(to: tab)
        }
        for sub in view.subviews {
            walkBarsOnly(sub, depth: depth + 1)
        }
    }

    private static func walkPolish(_ view: UIView, depth: Int) {
        guard depth < 12 else { return }
        if GlassMediaExclusion.shouldSkipGlass(for: view) { return }
        let prefs = GlassPreferences.shared

        if prefs.styleButtons, let btn = view as? UIButton, !(btn is GlassSettingsButton) {
            polishButton(btn)
        }
        if prefs.styleCards {
            polishCard(view)
        }
        for sub in view.subviews {
            walkPolish(sub, depth: depth + 1)
        }
    }

    private static func polishButton(_ button: UIButton) {
        let title = ((button.title(for: .normal) ?? button.currentTitle ?? "")
            + " " + (button.accessibilityLabel ?? "")).lowercased()
        let blocked = ["follow", "following", "message", "share", "like", "comment",
                       "post", "send", "reply", "story", "reels", "live"]
        if blocked.contains(where: { title.contains($0) }) { return }
        if button.bounds.width > 160 && button.bounds.height > 44 { return }
        if button.layer.cornerRadius > 0 {
            button.layer.cornerCurve = .continuous
        }
        button.layer.borderWidth = 0
    }

    private static func polishCard(_ view: UIView) {
        if view is UIControl || view is UIButton || view is UILabel { return }
        if view.layer.cornerRadius >= 8 {
            view.layer.cornerCurve = .continuous
        }
        if view.layer.borderWidth > 0 && view.layer.borderWidth <= 0.6 {
            let name = NSStringFromClass(type(of: view))
            if name.contains("Glass") { return }
            if view.layer.borderColor == UIColor.white.withAlphaComponent(0.10).cgColor
                || view.layer.borderColor == UIColor.white.withAlphaComponent(0.18).cgColor {
                view.layer.borderWidth = 0
            }
        }
    }
}
