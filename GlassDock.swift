import UIKit

/// Small floating iOS-26 tab dock + moving selected bubble.
/// Finds real UITabBar OR Instagram-style bottom chrome by heuristics.
@objc public final class GlassDock: NSObject {

    @objc public static let shared = GlassDock()

    private var lastLayout: TimeInterval = 0
    private var lastSelectedIndex: Int = -1
    private var scrollOffset: CGFloat = 0
    private var dockCollapsed: Bool = false
    private weak var lastBar: UIView?

    private override init() { super.init() }

    @objc public func attachIfNeeded() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode, prefs.styleTabBar else {
            NSLog("[GlossyGlass] Dock skip: enabled=%d safe=%d styleTab=%d",
                  prefs.isEnabled ? 1 : 0, prefs.safeMode ? 1 : 0, prefs.styleTabBar ? 1 : 0)
            return
        }
        var found = false
        for w in GlassAppSupport.allWindows() {
            if let bar = findTabBar(in: w, depth: 0) {
                install(on: bar)
                found = true
                break
            }
        }
        if !found {
            // Heuristic bottom chrome (IG often does not use UITabBar)
            for w in GlassAppSupport.allWindows() {
                if let bar = findBottomChrome(in: w, depth: 0) {
                    install(on: bar)
                    found = true
                    break
                }
            }
        }
        NSLog("[GlossyGlass] Dock attach found=%d", found ? 1 : 0)
    }

    @objc public func onLayout(_ bar: UIView) {
        install(on: bar)
    }

    @objc public func onScroll(offsetY: CGFloat) {
        let delta = offsetY - scrollOffset
        scrollOffset = offsetY
        if delta > 6 { setCollapsed(true) }
        else if delta < -6 { setCollapsed(false) }
    }

    @objc public func settle() { setCollapsed(false) }

    // MARK: - Find

    private func findTabBar(in view: UIView, depth: Int) -> UIView? {
        guard depth < 16 else { return nil }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if view is UITabBar { return view }
        if n.contains("igtabbar") || n.contains("maintabbar") {
            if view.bounds.height > 28, view.bounds.height < 120 { return view }
        }
        if n.contains("tabbar") && view.bounds.width > 200 && view.bounds.height > 28 && view.bounds.height < 100 {
            return view
        }
        // Don't skip scroll views entirely — IG nests tab bar oddly; only skip cells
        if view is UICollectionViewCell || view is UITableViewCell { return nil }
        for s in view.subviews {
            if let f = findTabBar(in: s, depth: depth + 1) { return f }
        }
        return nil
    }

    /// Bottom-of-window strip with multiple controls — typical IG main chrome.
    private func findBottomChrome(in view: UIView, depth: Int) -> UIView? {
        guard depth < 12 else { return nil }
        let b = view.bounds
        let screenH = UIScreen.main.bounds.height
        // Candidate: wide, short, near bottom of screen
        if b.width > UIScreen.main.bounds.width * 0.85,
           b.height >= 40, b.height <= 100 {
            let originInWindow: CGPoint
            if let w = view.window {
                originInWindow = view.convert(CGPoint.zero, to: w)
            } else {
                originInWindow = view.convert(CGPoint.zero, to: nil)
            }
            if originInWindow.y + b.height > screenH - 120 {
                // Must have several interactive children
                let controls = view.subviews.filter {
                    $0 is UIControl || NSStringFromClass(type(of: $0)).lowercased().contains("button")
                        || NSStringFromClass(type(of: $0)).lowercased().contains("tab")
                }
                if controls.count >= 3 { return view }
            }
        }
        if view is UICollectionViewCell || view is UITableViewCell { return nil }
        for s in view.subviews {
            if let f = findBottomChrome(in: s, depth: depth + 1) { return f }
        }
        return nil
    }

    // MARK: - Install

    private func install(on bar: UIView) {
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastLayout < 0.04 { return }
        lastLayout = now
        lastBar = bar

        // Never skip our own tab chrome for media reasons
        let n = NSStringFromClass(type(of: bar)).lowercased()
        if !(bar is UITabBar || n.contains("tabbar") || n.contains("igtab")) {
            if GlassMediaExclusion.shouldSkipGlass(for: bar) { return }
        }

        GlassChromeShield.shared.neutralizeStock(bar)
        if let tab = bar as? UITabBar {
            GlassNavigationHelper.applyTabBarStyle(to: tab)
        }

        let b = bar.bounds
        guard b.width > 100, b.height > 24 else { return }

        let prefs = GlassPreferences.shared
        let side: CGFloat = 18
        let baseH: CGFloat = dockCollapsed ? 40 : 54
        let bottomPad: CGFloat = max(6, bar.safeAreaInsets.bottom > 0 ? 8 : 12)
        let y = max(2, b.height - baseH - bottomPad)
        let dockFrame = CGRect(x: side, y: y, width: max(80, b.width - side * 2), height: baseH)

        let plate = GlassBubbleKit.installBubble(
            into: bar,
            tag: GlassBubbleKit.dockTag,
            frame: dockFrame,
            style: prefs.style,
            intensity: max(0.72, prefs.intensity),
            opacity: max(0.92, prefs.opacity)
        )
        plate.layer.shadowColor = UIColor.black.cgColor
        plate.layer.shadowOpacity = Float(0.28 * max(0.5, prefs.intensity))
        plate.layer.shadowRadius = 14
        plate.layer.shadowOffset = CGSize(width: 0, height: 5)
        plate.layer.masksToBounds = false
        plate.clipsToBounds = true
        plate.isUserInteractionEnabled = false
        plate.isHidden = false
        plate.alpha = 1

        alignItems(in: bar, dock: dockFrame)
        updateSelectedBubble(in: bar, dock: dockFrame)

        // Icons above glass
        for sub in bar.subviews {
            if sub.tag == GlassBubbleKit.dockTag || sub.tag == GlassBubbleKit.selectedTag { continue }
            bar.bringSubviewToFront(sub)
        }
        if let sel = bar.viewWithTag(GlassBubbleKit.selectedTag) {
            bar.insertSubview(sel, aboveSubview: plate)
        }
    }

    private func alignItems(in bar: UIView, dock: CGRect) {
        let midY = dock.midY
        for sub in bar.subviews {
            if sub.tag == GlassBubbleKit.dockTag || sub.tag == GlassBubbleKit.selectedTag { continue }
            let sn = NSStringFromClass(type(of: sub)).lowercased()
            let isItem = sn.contains("button") || sn.contains("tabbarbutton") || sn.contains("item")
                || sn.contains("tab") || (sub is UIControl && sub.bounds.width < 90)
            guard isItem else { continue }
            var f = sub.frame
            guard f.width > 10, f.height > 10, f.width < 120 else { continue }
            f.origin.y = midY - f.height / 2
            // Softly keep inside dock x-range
            if f.maxX < dock.minX || f.minX > dock.maxX { continue }
            sub.frame = f
        }
    }

    private func updateSelectedBubble(in bar: UIView, dock: CGRect) {
        let prefs = GlassPreferences.shared
        var selected: UIView?
        var index = 0
        var items: [UIView] = []

        for sub in bar.subviews {
            if sub.tag == GlassBubbleKit.dockTag || sub.tag == GlassBubbleKit.selectedTag { continue }
            let sn = NSStringFromClass(type(of: sub)).lowercased()
            let isItem = sn.contains("button") || sn.contains("tabbarbutton") || sn.contains("item")
                || (sub is UIControl && sub.bounds.width < 90)
            guard isItem, sub.bounds.width > 10, sub.bounds.height > 10 else { continue }
            items.append(sub)
            let ctrl = sub as? UIControl
            let highlighted = ctrl?.isSelected == true
                || ctrl?.isHighlighted == true
                || sub.tintColor == .systemBlue
                || abs(sub.transform.a - 1.0) > 0.01
            if highlighted { selected = sub; lastSelectedIndex = index }
            index += 1
        }

        if selected == nil, lastSelectedIndex >= 0, lastSelectedIndex < items.count {
            selected = items[lastSelectedIndex]
        }
        guard let target = selected else {
            bar.viewWithTag(GlassBubbleKit.selectedTag)?.isHidden = true
            return
        }

        let pad: CGFloat = 6
        var f = target.frame.insetBy(dx: -pad, dy: -pad)
        f.size.width = max(f.width, 36)
        f.size.height = max(f.height, 36)
        // Clamp into dock
        f.origin.x = max(dock.minX + 4, min(f.origin.x, dock.maxX - f.width - 4))
        f.origin.y = max(dock.minY + 2, min(f.origin.y, dock.maxY - f.height - 2))

        let bubble = GlassBubbleKit.installSelectedLens(
            into: bar,
            frame: f,
            intensity: max(0.8, prefs.intensity)
        )
        // Morph to frame
        UIView.animate(withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.4, options: [.allowUserInteraction]) {
            bubble.frame = f
        }
        bubble.isHidden = false
        bubble.alpha = 1
    }

    private func setCollapsed(_ collapsed: Bool) {
        guard dockCollapsed != collapsed else { return }
        dockCollapsed = collapsed
        if let bar = lastBar {
            UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
                self.install(on: bar)
            }
        }
    }
}
