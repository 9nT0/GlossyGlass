import UIKit

/// Applies liquid-glass materials to the *real* tab bar only.
/// No floating capsules, no bottom-of-screen overlays (those covered DM/story inputs).
@objc public final class GlassLiquidTabBar: NSObject {

    @objc public static let shared = GlassLiquidTabBar()

    private var observer: NSObjectProtocol?
    private var timer: Timer?

    private override init() { super.init() }

    @objc public func start() {
        DispatchQueue.main.async {
            if self.observer == nil {
                self.observer = NotificationCenter.default.addObserver(
                    forName: .glassPreferencesDidChange,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in self?.refresh() }
            }
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                self?.refresh()
            }
            self.refresh()
        }
    }

    @objc public func refresh() {
        let prefs = GlassPreferences.shared
        // Strip any leftover capsule overlays from older builds
        stripLegacyCapsules()

        guard prefs.isEnabled, prefs.styleTabBar, !prefs.safeMode else { return }

        for window in GlassAppSupport.allWindows() {
            applyToRealTabBars(in: window, depth: 0)
        }
    }

    private func stripLegacyCapsules() {
        for window in GlassAppSupport.allWindows() {
            strip(in: window, depth: 0)
        }
    }

    private func strip(in view: UIView, depth: Int) {
        guard depth < 20 else { return }
        // Remove tagged blur inserts from older builds
        for sub in view.subviews {
            if sub.tag == 0x4747_5442 || sub.tag == 0x4747_424C || sub.tag == 0x4747_484C {
                sub.removeFromSuperview()
                continue
            }
            // Legacy LiquidCapsuleView class name
            let name = NSStringFromClass(type(of: sub))
            if name.contains("LiquidCapsule") {
                sub.removeFromSuperview()
                continue
            }
            strip(in: sub, depth: depth + 1)
        }
    }

    private func applyToRealTabBars(in view: UIView, depth: Int) {
        guard depth < 18 else { return }
        if let tab = view as? UITabBar {
            GlassNavigationHelper.applyTabBarStyle(to: tab)
        }
        for sub in view.subviews {
            applyToRealTabBars(in: sub, depth: depth + 1)
        }
    }
}
