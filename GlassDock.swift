import UIKit

/// Small floating iOS-26 tab dock + moving selected bubble.
/// Keeps real IG tab buttons/actions — only paints plate + indicator.
@objc public final class GlassDock: NSObject {

    @objc public static let shared = GlassDock()
    private var lastLayout: TimeInterval = 0
    private var lastSelectedIndex: Int = -1

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

    @objc public func onLayout(_ bar: UIView) {
        install(on: bar)
    }

    private func findTabBar(in view: UIView, depth: Int) -> UIView? {
        guard depth < 12 else { return nil }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if view is UITabBar || n.contains("igtabbar") { return view }
        for s in view.subviews {
            if let f = findTabBar(in: s, depth: depth + 1) { return f }
        }
        return nil
    }

    private func install(on bar: UIView) {
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastLayout < 0.06 { return }
        lastLayout = now

        if GlassMediaExclusion.shouldSkipGlass(for: bar) { return }

        // Full bar transparent — glass only on floating dock
        GlassChromeShield.shared.neutralizeStock(bar)
        if let tab = bar as? UITabBar {
            GlassNavigationHelper.applyTabBarStyle(to: tab)
        }

        let b = bar.bounds
        guard b.width > 100, b.height > 28 else { return }

        let prefs = GlassPreferences.shared
        // SMALL floating dock — inset, not edge-to-edge
        let side: CGFloat = 18
        let dockH: CGFloat = 50
        let bottomPad: CGFloat = max(2, bar.safeAreaInsets.bottom > 0 ? 4 : 8)
        let y = max(4, b.height - dockH - bottomPad)
        let dockFrame = CGRect(x: side, y: y, width: b.width - side * 2, height: dockH)

        let plate = GlassBubbleKit.installBubble(
            into: bar,
            tag: GlassBubbleKit.dockTag,
            frame: dockFrame,
            style: prefs.style,
            intensity: max(0.7, prefs.intensity),
            opacity: max(0.92, prefs.opacity)
        )
        // Also set plateTag so older strip code finds it
        plate.tag = GlassBubbleKit.dockTag

        // Align IG tab item views into dock band (keep actions)
        alignItems(in: bar, dock: dockFrame)

        // Moving selected bubble
        updateSelectedBubble(in: bar, dock: dockFrame)

        // Icons above glass
        for sub in bar.subviews {
            if sub.tag == GlassBubbleKit.dockTag || sub.tag == GlassBubbleKit.selectedTag { continue }
            bar.bringSubviewToFront(sub)
        }
        // Selected under icons but above plate
        if let sel = bar.viewWithTag(GlassBubbleKit.selectedTag) {
            bar.insertSubview(sel, aboveSubview: plate)
        }
    }

    private func alignItems(in bar: UIView, dock: CGRect) {
        let midY = dock.midY
        for sub in bar.subviews {
            if sub.tag == GlassBubbleKit.dockTag || sub.tag == GlassBubbleKit.selectedTag { continue }
            let sn = NSStringFromClass(type(of: sub)).lowercased()
            if sn.contains("button") || sn.contains("tabbarbutton") || sn.contains("item")
                || (sub is UIControl && sub.bounds.width < bar.bounds.width * 0.28) {
                var f = sub.frame
                guard f.height > 6, f.width > 6 else { continue }
                f.origin.y = midY - f.height * 0.5
                sub.frame = f
            }
        }
    }

    private func updateSelectedBubble(in bar: UIView, dock: CGRect) {
        var index = 0
        var count = 5
        if let tab = bar as? UITabBar, let items = tab.items, let sel = tab.selectedItem,
           let idx = items.firstIndex(of: sel) {
            index = idx
            count = max(1, items.count)
        }

        let slot = dock.width / CGFloat(count)
        let bubbleW = min(56, slot * 0.72)
        let bubbleH = min(40, dock.height * 0.72)
        let target = CGRect(
            x: dock.minX + CGFloat(index) * slot + (slot - bubbleW) * 0.5,
            y: dock.minY + (dock.height - bubbleH) * 0.5,
            width: bubbleW,
            height: bubbleH
        )

        let prefs = GlassPreferences.shared
        let bubble: UIView
        if let existing = bar.viewWithTag(GlassBubbleKit.selectedTag) {
            bubble = existing
            if index != lastSelectedIndex {
                GlassBubbleKit.springMove(bubble, to: target)
            } else {
                bubble.frame = target
            }
        } else {
            // Soft glass lens (UIView + blur child on content path without nesting issues)
            let holder = UIView(frame: target)
            holder.tag = GlassBubbleKit.selectedTag
            holder.isUserInteractionEnabled = false
            holder.layer.cornerRadius = bubbleH * 0.42
            if #available(iOS 13.0, *) { holder.layer.cornerCurve = .continuous }
            holder.clipsToBounds = true
            holder.backgroundColor = UIColor.white.withAlphaComponent(0.18 * prefs.intensity)
            holder.layer.borderWidth = 0.4
            holder.layer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
            bar.insertSubview(holder, at: 1)
            bubble = holder
        }
        lastSelectedIndex = index
        bubble.alpha = max(0.55, prefs.intensity)
    }
}
