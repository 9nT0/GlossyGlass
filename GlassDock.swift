import UIKit

/// Small floating iOS-26 tab dock + moving selected bubble.
/// Keeps real IG tab buttons/actions — only paints plate + indicator.
/// Single instance: never destroy/recreate whole dock on tab change.
@objc public final class GlassDock: NSObject {

    @objc public static let shared = GlassDock()

    private var lastLayout: TimeInterval = 0
    private var lastSelectedIndex: Int = -1
    private var scrollOffset: CGFloat = 0
    private var dockCollapsed: Bool = false

    private override init() { super.init() }

    // MARK: - Public

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

    /// Scroll-aware dock: shorten/fade on scroll down, expand on scroll up.
    @objc public func onScroll(offsetY: CGFloat) {
        let delta = offsetY - scrollOffset
        scrollOffset = offsetY
        if delta > 4 {
            setCollapsed(true)
        } else if delta < -4 {
            setCollapsed(false)
        }
    }

    @objc public func settle() {
        setCollapsed(false)
    }

    // MARK: - Find

    private func findTabBar(in view: UIView, depth: Int) -> UIView? {
        guard depth < 14 else { return nil }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if view is UITabBar || n.contains("igtabbar") { return view }
        // Skip heavy media / collection trees
        if view is UICollectionView || view is UITableView { return nil }
        for s in view.subviews {
            if let f = findTabBar(in: s, depth: depth + 1) { return f }
        }
        return nil
    }

    // MARK: - Install (create-or-update)

    private func install(on bar: UIView) {
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastLayout < 0.05 { return }
        lastLayout = now

        if GlassMediaExclusion.shouldSkipGlass(for: bar) { return }
        if !GlassChromeShield.isAllowedChrome(bar) { return }

        // Full bar transparent — glass only on floating dock
        GlassChromeShield.shared.neutralizeStock(bar)
        if let tab = bar as? UITabBar {
            GlassNavigationHelper.applyTabBarStyle(to: tab)
        }

        let b = bar.bounds
        guard b.width > 120, b.height > 28 else { return }

        let prefs = GlassPreferences.shared
        // SMALL floating dock — inset ~16–20pt, height ~49–54
        let side: CGFloat = 16
        let baseH: CGFloat = dockCollapsed ? 42 : 52
        let bottomPad: CGFloat = max(4, bar.safeAreaInsets.bottom > 0 ? 6 : 10)
        let y = max(2, b.height - baseH - bottomPad)
        let dockFrame = CGRect(x: side, y: y, width: b.width - side * 2, height: baseH)

        let plate = GlassBubbleKit.installBubble(
            into: bar,
            tag: GlassBubbleKit.dockTag,
            frame: dockFrame,
            style: prefs.style,
            intensity: max(0.68, prefs.intensity),
            opacity: max(0.90, prefs.opacity)
        )
        // Depth shadow on dock
        plate.layer.shadowColor = UIColor.black.cgColor
        plate.layer.shadowOpacity = Float(0.22 * prefs.intensity)
        plate.layer.shadowRadius = 12
        plate.layer.shadowOffset = CGSize(width: 0, height: 4)
        plate.layer.masksToBounds = false
        plate.clipsToBounds = true

        alignItems(in: bar, dock: dockFrame)
        updateSelectedBubble(in: bar, dock: dockFrame)

        // Z-order: plate → selected → icons
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
                || (sub is UIControl && sub.bounds.width < bar.bounds.width * 0.28)
            guard isItem else { continue }
            var f = sub.frame
            guard f.height > 6, f.width > 6 else { continue }
            f.origin.y = midY - f.height * 0.5
            sub.frame = f
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
        let bubbleW = min(54, max(36, slot * 0.70))
        let bubbleH = min(38, dock.height * 0.70)
        let target = CGRect(
            x: dock.minX + CGFloat(index) * slot + (slot - bubbleW) * 0.5,
            y: dock.minY + (dock.height - bubbleH) * 0.5,
            width: bubbleW,
            height: bubbleH
        )

        let prefs = GlassPreferences.shared
        let lens = GlassBubbleKit.installSelectedLens(
            into: bar,
            frame: (index == lastSelectedIndex)
                ? (bar.viewWithTag(GlassBubbleKit.selectedTag)?.frame ?? target)
                : target,
            intensity: prefs.intensity
        )

        if index != lastSelectedIndex {
            GlassBubbleKit.springMove(lens, to: target)
            if prefs.hapticsEnabled {
                let gen = UISelectionFeedbackGenerator()
                gen.selectionChanged()
            }
        } else if lens.layer.animationKeys()?.isEmpty ?? true {
            lens.frame = target
        }
        lastSelectedIndex = index
    }

    private func setCollapsed(_ collapsed: Bool) {
        guard collapsed != dockCollapsed else { return }
        dockCollapsed = collapsed
        // Next layout pass will shrink/expand; force soft refresh
        lastLayout = 0
        attachIfNeeded()
    }
}
