import UIKit

/// Runs as early as possible after dylib load.
/// Makes known IG chrome transparent BEFORE first paint so stock bars never flash.
@objc public final class GlassInstantShield: NSObject {

    @objc public static let shared = GlassInstantShield()
    private static var didRun = false

    @objc public static func arm() {
        // Sync on main if already main; otherwise async ASAP
        if Thread.isMainThread {
            shared.run()
        } else {
            DispatchQueue.main.async { shared.run() }
        }
        // Also retry a few times during first frames only
        for d in [0.0, 0.05, 0.12, 0.25] as [TimeInterval] {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                shared.run()
            }
        }
    }

    private func run() {
        for w in GlassAppSupport.allWindows() {
            neutralize(w, depth: 0)
        }
    }

    private func neutralize(_ view: UIView, depth: Int) {
        guard depth < 10 else { return }
        let lower = NSStringFromClass(type(of: view)).lowercased()

        if view is UITabBar || lower.contains("igtabbar") {
            view.backgroundColor = .clear
            view.isOpaque = false
            if let tab = view as? UITabBar {
                let a = UITabBarAppearance()
                a.configureWithTransparentBackground()
                a.backgroundEffect = nil
                a.backgroundColor = .clear
                a.shadowColor = .clear
                tab.standardAppearance = a
                tab.scrollEdgeAppearance = a
                tab.isTranslucent = true
                tab.barTintColor = .clear
                tab.backgroundImage = UIImage()
                tab.shadowImage = UIImage()
            }
        }
        if view is UINavigationBar || lower.contains("ignavigationbar") {
            view.backgroundColor = .clear
            view.isOpaque = false
            if let nav = view as? UINavigationBar {
                let a = UINavigationBarAppearance()
                a.configureWithTransparentBackground()
                a.backgroundEffect = nil
                a.backgroundColor = .clear
                a.shadowColor = .clear
                nav.standardAppearance = a
                nav.scrollEdgeAppearance = a
                nav.isTranslucent = true
                nav.barTintColor = .clear
            }
        }
        for s in view.subviews { neutralize(s, depth: depth + 1) }
    }
}
