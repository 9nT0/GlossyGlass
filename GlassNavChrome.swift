import UIKit

/// Small control capsules on nav — never a full-width slab.
@objc public final class GlassNavChrome: NSObject {

    @objc public static let shared = GlassNavChrome()
    private var lastApply: TimeInterval = 0

    @objc public func apply() {
        for w in GlassAppSupport.allWindows() {
            if let bar = findNavBar(in: w, depth: 0) {
                apply(to: bar)
            }
        }
    }

    @objc public func apply(to bar: UIView) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode, prefs.styleNavigationBar else { return }
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastApply < 0.08 { return }
        lastApply = now

        // Clear stock bar background completely
        GlassChromeShield.shared.neutralizeStock(bar)
        if let nav = bar as? UINavigationBar {
            GlassNavigationHelper.applyNavigationBarStyle(to: nav)
        }

        styleControlBubbles(in: bar)
    }

    private func findNavBar(in view: UIView, depth: Int) -> UIView? {
        guard depth < 14 else { return nil }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if view is UINavigationBar { return view }
        if n.contains("ignavigationbar") || (n.contains("navigationbar") && view.bounds.height > 28 && view.bounds.height < 120) {
            return view
        }
        if view is UICollectionViewCell || view is UITableViewCell { return nil }
        for s in view.subviews {
            if let f = findNavBar(in: s, depth: depth + 1) { return f }
        }
        return nil
    }

    private func styleControlBubbles(in bar: UIView) {
        let prefs = GlassPreferences.shared
        var bubbleIndex = 0
        let maxBubbles = 6

        for sub in bar.subviews {
            if bubbleIndex >= maxBubbles { break }
            let sn = NSStringFromClass(type(of: sub)).lowercased()

            // Skip title / large content / our glass
            if sub is UILabel { continue }
            if isGG(sub.tag) { continue }
            if sn.contains("contentview") || sn.contains("prompt") || sn.contains("title") { continue }
            if sn.contains("button") == false && !(sub is UIControl) && sn.contains("barbutton") == false {
                // Still allow small circular controls
                if sub.bounds.width > 52 || sub.bounds.height > 52 { continue }
            }

            let isControl = sn.contains("button") || sub is UIControl || sn.contains("barbutton")
                || sn.contains("uibarbutton") || sn.contains("back")
            guard isControl || (sub.bounds.width <= 48 && sub.bounds.height <= 48 && sub.subviews.count <= 3) else {
                continue
            }

            let f = sub.frame
            guard f.width > 12, f.height > 12, f.width < 96, f.height < 52 else { continue }

            let pad: CGFloat = 4
            let bubbleFrame = f.insetBy(dx: -pad, dy: -pad)
            let tag = GlassBubbleKit.navBubbleTag &+ bubbleIndex
            bubbleIndex += 1

            let b = GlassBubbleKit.installBubble(
                into: bar,
                tag: tag,
                frame: bubbleFrame,
                style: prefs.style,
                intensity: max(0.65, prefs.intensity),
                opacity: max(0.88, prefs.opacity)
            )
            b.isUserInteractionEnabled = false
            bar.insertSubview(b, belowSubview: sub)
        }
        // Raise real controls above bubbles
        for sub in bar.subviews {
            if isGG(sub.tag) { continue }
            bar.bringSubviewToFront(sub)
        }
    }

    private func isGG(_ tag: Int) -> Bool {
        tag == GlassBubbleKit.dockTag
            || tag == GlassBubbleKit.selectedTag
            || tag == GlassBubbleKit.plateTag
            || (tag >= GlassBubbleKit.navBubbleTag && tag < GlassBubbleKit.navBubbleTag &+ 32)
            || (tag >= 0x4747_0000 && tag <= 0x4747_FFFF)
    }
}
