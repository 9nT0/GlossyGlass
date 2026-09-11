import UIKit

/// Glass-owned floating tab dock.
/// Keeps Instagram tab actions; owns dock frame so IG can't resize the glass container.
@objc public final class GlassDock: NSObject {

    @objc public static let shared = GlassDock()

    private let dockTag = 0x4747_444B // GGDK
    private let plateTag = 0x4747_4D41
    private weak var hostBar: UIView?
    private var lastLayout: TimeInterval = 0

    private override init() { super.init() }

    @objc public func attachIfNeeded() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode, prefs.styleTabBar else { return }

        for w in GlassAppSupport.allWindows() {
            if let bar = findTabBar(in: w, depth: 0) {
                install(on: bar)
                return
            }
        }
    }

    private func findTabBar(in view: UIView, depth: Int) -> UIView? {
        guard depth < 12 else { return nil }
        let lower = NSStringFromClass(type(of: view)).lowercased()
        if view is UITabBar || lower.contains("igtabbar") {
            return view
        }
        for s in view.subviews {
            if let f = findTabBar(in: s, depth: depth + 1) { return f }
        }
        return nil
    }

    private func install(on bar: UIView) {
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastLayout < 0.08 { return }
        lastLayout = now
        hostBar = bar

        // Neutralize stock full-width fill
        GlassMaterialEngine.shared.neutralizeStockChrome(bar)
        if let tab = bar as? UITabBar {
            GlassNavigationHelper.applyTabBarStyle(to: tab)
        }

        let b = bar.bounds
        guard b.width > 80, b.height > 20 else { return }

        // Glass-owned dock frame — smaller, inset, continuous
        let side: CGFloat = 20
        let dockH: CGFloat = 38
        let y: CGFloat = 6
        let dockFrame = CGRect(x: side, y: y, width: b.width - side * 2, height: dockH)

        let prefs = GlassPreferences.shared
        let effect = GlassMaterialEngine.shared.blurEffect(
            style: prefs.style, dark: true, intensity: max(0.65, prefs.intensity)
        )

        let plate: UIVisualEffectView
        if let e = bar.viewWithTag(plateTag) as? UIVisualEffectView {
            plate = e
            plate.effect = effect
        } else {
            plate = UIVisualEffectView(effect: effect)
            plate.tag = plateTag
            plate.isUserInteractionEnabled = false
            plate.clipsToBounds = true
            bar.insertSubview(plate, at: 0)
        }
        plate.frame = dockFrame
        plate.layer.cornerRadius = dockH * 0.48
        if #available(iOS 13.0, *) { plate.layer.cornerCurve = .continuous }
        plate.alpha = max(0.92, prefs.opacity)

        // Inner tint + rim on contentView only
        GlassMaterialEngine.shared.install(into: bar, style: prefs.style, intensity: prefs.intensity, opacity: prefs.opacity, compact: true)
        // Override frame after install (install sets its own geometry)
        if let p = bar.viewWithTag(plateTag) as? UIVisualEffectView {
            p.frame = dockFrame
            p.layer.cornerRadius = dockH * 0.48
            if #available(iOS 13.0, *) { p.layer.cornerCurve = .continuous }
        }

        // Move tab item views into dock vertical band (keep actions — only frames)
        alignItems(in: bar, dock: dockFrame)

        // Selected lens
        if let tab = bar as? UITabBar, let items = tab.items, let sel = tab.selectedItem,
           let idx = items.firstIndex(of: sel) {
            GlassMaterialEngine.shared.updateSelectedLens(in: bar, index: idx, count: items.count)
        }

        for sub in bar.subviews where sub.tag != plateTag {
            bar.bringSubviewToFront(sub)
        }
    }

    private func alignItems(in bar: UIView, dock: CGRect) {
        let midY = dock.midY
        for sub in bar.subviews {
            if sub.tag == plateTag { continue }
            let sn = NSStringFromClass(type(of: sub)).lowercased()
            // Tab buttons / item containers
            if sn.contains("button") || sn.contains("tabbarbutton") || sn.contains("item")
                || (sub is UIControl && sub.bounds.width < bar.bounds.width * 0.3) {
                var f = sub.frame
                guard f.height > 4, f.width > 4 else { continue }
                // Keep x (IG owns horizontal layout for 5 tabs); lock y to dock center
                f.origin.y = midY - f.height * 0.5
                // Clamp width so items stay inside dock horizontally if overflowing
                if f.maxX > dock.maxX - 4 {
                    f.origin.x = max(dock.minX + 4, dock.maxX - 4 - f.width)
                }
                if f.minX < dock.minX + 4 {
                    f.origin.x = dock.minX + 4
                }
                sub.frame = f
            }
        }
    }

    @objc public func onLayout(_ bar: UIView) {
        install(on: bar)
    }
}
