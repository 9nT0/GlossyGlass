import UIKit

/// Actively applies nav/tab/button/card glass so toggles are not half-dead.
@objc public class GlassStyleApplicator: NSObject {

    private static var observer: NSObjectProtocol?
    private static var timer: Timer?
    private static var started = false

    @objc public static func start() {
        DispatchQueue.main.async {
            guard !started else {
                applyAll()
                return
            }
            started = true

            observer = NotificationCenter.default.addObserver(
                forName: .glassPreferencesDidChange,
                object: nil,
                queue: .main
            ) { _ in applyAll() }

            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
                applyAll()
            }

            applyAll()
            // Early passes
            for d in [0.8, 2.0, 4.0, 7.0] as [TimeInterval] {
                DispatchQueue.main.asyncAfter(deadline: .now() + d) { applyAll() }
            }
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
        guard depth < 22 else { return }
        let prefs = GlassPreferences.shared

        if let nav = view as? UINavigationBar, prefs.styleNavigationBar {
            GlassNavigationHelper.applyNavigationBarStyle(to: nav)
        }
        if let tab = view as? UITabBar, prefs.styleTabBar {
            GlassNavigationHelper.applyTabBarStyle(to: tab)
        }
        if prefs.styleButtons {
            if let btn = view as? UIButton, !(btn is GlassSettingsButton) {
                applyButtonChrome(btn)
            }
        }
        if prefs.styleCards {
            applyCardIfLikely(view)
        }

        for sub in view.subviews {
            walk(sub, depth: depth + 1)
        }
    }

    private static func applyButtonChrome(_ button: UIButton) {
        // Subtle glass edge — visible but not aggressive
        if button.layer.cornerRadius < 1 { button.layer.cornerRadius = 10 }
        button.layer.cornerCurve = .continuous
        if button.backgroundColor == nil || button.backgroundColor == .clear {
            let isDark = button.traitCollection.userInterfaceStyle == .dark
            button.backgroundColor = UIColor.white.withAlphaComponent(isDark ? 0.08 : 0.12)
        }
        button.clipsToBounds = true
    }

    private static func applyCardIfLikely(_ view: UIView) {
        // Heuristic: large rounded views / cells
        let name = NSStringFromClass(type(of: view))
        let looksCard = name.contains("Cell") || name.contains("Card") || name.contains("Collection")
            || (view.bounds.height > 60 && view.bounds.width > 120 && view.layer.cornerRadius >= 8)
        guard looksCard else { return }
        guard view.backgroundColor != nil || view.layer.cornerRadius > 0 else { return }

        view.layer.cornerCurve = .continuous
        if view.layer.cornerRadius < 8 { view.layer.cornerRadius = 14 }
        // Soft border
        if view.layer.borderWidth < 0.2 {
            let isDark = view.traitCollection.userInterfaceStyle == .dark
            view.layer.borderWidth = 0.4
            view.layer.borderColor = UIColor.white.withAlphaComponent(isDark ? 0.10 : 0.18).cgColor
        }
    }
}
