import UIKit

/// Appearance polish for system bars only. Floating glass is GlassDock / GlassNavChrome.
@objc public class GlassStyleApplicator: NSObject {

    private static var started = false
    private static var observer: NSObjectProtocol?

    @objc public static func start() {
        DispatchQueue.main.async {
            if !started {
                started = true
                observer = NotificationCenter.default.addObserver(
                    forName: .glassPreferencesDidChange,
                    object: nil, queue: .main
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
    }

    @objc public static func applyToView(_ view: UIView) {
        // No-op deep walk — coordinator owns chrome
    }

    @objc public static func applyAll() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        GlassChromeCoordinator.shared.apply(reason: "styleApplicator")
        // Transparent system bar appearances only
        for w in GlassAppSupport.allWindows() {
            walkBars(w, depth: 0)
        }
    }

    private static func walkBars(_ view: UIView, depth: Int) {
        guard depth < 14 else { return }
        if view is UICollectionViewCell || view is UITableViewCell { return }
        if let nav = view as? UINavigationBar, GlassPreferences.shared.styleNavigationBar {
            GlassNavigationHelper.applyNavigationBarStyle(to: nav)
        }
        if let tab = view as? UITabBar, GlassPreferences.shared.styleTabBar {
            GlassNavigationHelper.applyTabBarStyle(to: tab)
        }
        for s in view.subviews { walkBars(s, depth: depth + 1) }
    }
}
