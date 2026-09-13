import UIKit

/// iOS-26 nav: CLEAR bar background, small glass capsules on controls only.
/// Never installs a full-width glass plate.
@objc public final class GlassNavChrome: NSObject {

    @objc public static let shared = GlassNavChrome()
    private var lastApply: TimeInterval = 0

    @objc public func apply() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode, prefs.styleNavigationBar else { return }
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastApply < 0.08 { return }
        lastApply = now
        for w in GlassAppSupport.allWindows() {
            walk(w, depth: 0)
        }
    }

    @objc public func apply(to bar: UINavigationBar) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, prefs.styleNavigationBar else { return }
        if GlassMediaExclusion.shouldSkipGlass(for: bar) { return }

        // CLEAR full bar — no slab
        GlassMaterialEngine.shared.neutralizeStockChrome(bar)
        GlassNavigationHelper.applyNavigationBarStyle(to: bar)

        // Kill any legacy full-width plate
        if let full = bar.viewWithTag(GlassBubbleKit.plateTag) {
            full.removeFromSuperview()
        }
        if let full = bar.viewWithTag(GlassBubbleKit.dockTag) {
            // dock tag shouldn't live on nav
            if full.bounds.width > bar.bounds.width * 0.7 {
                full.removeFromSuperview()
            }
        }

        styleControlBubbles(in: bar)
    }

    private func walk(_ view: UIView, depth: Int) {
        guard depth < 12 else { return }
        if let nav = view as? UINavigationBar {
            apply(to: nav)
            return
        }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if n.contains("ignavigationbar") {
            view.backgroundColor = .clear
            view.isOpaque = false
            GlassMaterialEngine.shared.neutralizeStockChrome(view)
            // remove legacy slabs
            if let full = view.viewWithTag(GlassBubbleKit.plateTag) {
                full.removeFromSuperview()
            }
            styleControlBubbles(in: view)
            return
        }
        if view is UICollectionView || view is UITableView || view is UIScrollView {
            return
        }
        for s in view.subviews { walk(s, depth: depth + 1) }
    }

    private func styleControlBubbles(in bar: UIView) {
        let prefs = GlassPreferences.shared
        var bubbleIndex = 0
        let maxBubbles = 8

        for sub in bar.subviews {
            if bubbleIndex >= maxBubbles { break }
            let sn = NSStringFromClass(type(of: sub)).lowercased()

            // Skip title / large content / our own glass
            if sub is UILabel { continue }
            if sub.tag == GlassBubbleKit.plateTag
                || sub.tag == GlassBubbleKit.dockTag
                || (sub.tag >= GlassBubbleKit.navBubbleTag && sub.tag < GlassBubbleKit.navBubbleTag &+ 16) {
                continue
            }
            if sn.contains("contentview") || sn.contains("prompt") || sn.contains("title") { continue }

            let isControl = sn.contains("button") || sub is UIControl || sn.contains("barbutton")
                || sn.contains("uibarbutton")
            guard isControl else { continue }

            let f = sub.frame
            // Only small controls — never glass a title-sized region
            guard f.width > 14, f.height > 14, f.width < 100, f.height < 52 else { continue }

            let pad: CGFloat = 5
            let bubbleFrame = f.insetBy(dx: -pad, dy: -pad)
            let tag = GlassBubbleKit.navBubbleTag &+ bubbleIndex
            bubbleIndex += 1

            let b = GlassBubbleKit.installBubble(
                into: bar,
                tag: tag,
                frame: bubbleFrame,
                style: prefs.style,
                intensity: max(0.50, prefs.intensity * 0.95),
                opacity: max(0.82, prefs.opacity)
            )
            // Soft depth
            b.layer.shadowColor = UIColor.black.cgColor
            b.layer.shadowOpacity = 0.12
            b.layer.shadowRadius = 4
            b.layer.shadowOffset = CGSize(width: 0, height: 1)
            b.layer.masksToBounds = false

            bar.insertSubview(b, belowSubview: sub)
        }
    }
}
