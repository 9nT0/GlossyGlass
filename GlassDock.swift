import UIKit

/// Instagram-style iOS 26 floating liquid-glass dock.
/// Single presentation path: real bar preferred; deferred window fallback.
@objc public final class GlassDock: NSObject {

    @objc public static let shared = GlassDock()

    private var lastLayout: TimeInterval = 0
    private var lastSelectedIndex: Int = 0
    private var scrollOffset: CGFloat = 0
    private var dockCollapsed: Bool = false
    private weak var lastBar: UIView?
    private weak var windowDockHost: UIView?
    private var usingWindowFallback = false

    private static let windowHostTag = 0x4747_5748 // GGWH

    private override init() { super.init() }

    // MARK: - Public

    @objc public func attachIfNeeded() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode, prefs.styleTabBar else { return }

        var bar: UIView?
        for w in GlassAppSupport.allWindows() {
            if let found = findTabBar(in: w, depth: 0) ?? findBottomChrome(in: w, depth: 0) {
                bar = found
                break
            }
        }

        if let bar = bar {
            removeWindowFallback()
            usingWindowFallback = false
            installOnBar(bar)
            NSLog("[GlossyGlass] Dock on bar")
        } else {
            usingWindowFallback = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self = self else { return }
                var found: UIView?
                for w in GlassAppSupport.allWindows() {
                    if let b = self.findTabBar(in: w, depth: 0) ?? self.findBottomChrome(in: w, depth: 0) {
                        found = b
                        break
                    }
                }
                if let b = found {
                    self.removeWindowFallback()
                    self.usingWindowFallback = false
                    self.installOnBar(b)
                    NSLog("[GlossyGlass] Dock on bar (deferred)")
                } else {
                    self.installWindowFloatingDock()
                    NSLog("[GlossyGlass] Dock window fallback")
                }
            }
        }
    }

    @objc public func onLayout(_ bar: UIView) {
        removeWindowFallback()
        usingWindowFallback = false
        installOnBar(bar)
    }

    @objc public func onScroll(offsetY: CGFloat) {
        let delta = offsetY - scrollOffset
        scrollOffset = offsetY
        if delta > 12 { setCollapsed(true) }
        else if delta < -12 { setCollapsed(false) }
    }

    @objc public func settle() { setCollapsed(false) }

    // MARK: - Discovery

    private func findTabBar(in view: UIView, depth: Int) -> UIView? {
        guard depth < 16 else { return nil }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if view is UITabBar { return view }
        if (n.contains("igtabbar") || n.contains("maintabbar")),
           view.bounds.height > 28, view.bounds.height < 120 {
            return view
        }
        if n.contains("tabbar"), view.bounds.width > 200,
           view.bounds.height > 28, view.bounds.height < 100 {
            return view
        }
        if view is UICollectionViewCell || view is UITableViewCell { return nil }
        for s in view.subviews {
            if let f = findTabBar(in: s, depth: depth + 1) { return f }
        }
        return nil
    }

    private func findBottomChrome(in view: UIView, depth: Int) -> UIView? {
        guard depth < 12 else { return nil }
        let b = view.bounds
        let screenH = UIScreen.main.bounds.height
        if b.width > UIScreen.main.bounds.width * 0.82,
           b.height >= 40, b.height <= 100 {
            let originY: CGFloat
            if let w = view.window {
                originY = view.convert(CGPoint.zero, to: w).y
            } else {
                originY = view.convert(CGPoint.zero, to: nil).y
            }
            if originY + b.height > screenH - 140 {
                let controls = view.subviews.filter {
                    $0 is UIControl
                        || NSStringFromClass(type(of: $0)).lowercased().contains("button")
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

    // MARK: - On bar

    private func installOnBar(_ bar: UIView) {
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastLayout < 0.05 { return }
        lastLayout = now
        lastBar = bar

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
        // IG floating pill proportions
        let side: CGFloat = 20
        let baseH: CGFloat = dockCollapsed ? 36 : 50
        let bottomPad: CGFloat = max(5, bar.safeAreaInsets.bottom > 0 ? 7 : 9)
        let y = max(2, b.height - baseH - bottomPad)
        let dockFrame = CGRect(x: side, y: y, width: max(80, b.width - side * 2), height: baseH)

        let plate = GlassBubbleKit.installBubble(
            into: bar,
            tag: GlassBubbleKit.dockTag,
            frame: dockFrame,
            style: prefs.style,
            intensity: max(0.72, prefs.intensity),
            opacity: max(0.90, prefs.opacity)
        )
        plate.isUserInteractionEnabled = false

        alignItems(in: bar, dock: dockFrame)
        updateSelectedBubble(in: bar, dock: dockFrame)

        // Z-order: plate → lens → real icons (icons must receive touches)
        if let plate = bar.viewWithTag(GlassBubbleKit.dockTag) {
            bar.sendSubviewToBack(plate)
        }
        if let sel = bar.viewWithTag(GlassBubbleKit.selectedTag),
           let plate = bar.viewWithTag(GlassBubbleKit.dockTag) {
            bar.insertSubview(sel, aboveSubview: plate)
        }
        for sub in collectTabItems(in: bar) {
            bar.bringSubviewToFront(sub)
            sub.isUserInteractionEnabled = true
        }
    }

    // MARK: - Window fallback

    private func installWindowFloatingDock() {
        guard let win = keyWindow() else { return }
        let host: UIView
        if let existing = win.viewWithTag(Self.windowHostTag) {
            host = existing
        } else {
            host = UIView()
            host.tag = Self.windowHostTag
            host.isUserInteractionEnabled = false
            host.backgroundColor = .clear
            win.addSubview(host)
        }
        windowDockHost = host

        let safeBottom = win.safeAreaInsets.bottom
        let side: CGFloat = 22
        let h: CGFloat = dockCollapsed ? 38 : 50
        let y = win.bounds.height - safeBottom - h - 10
        let frame = CGRect(x: side, y: y, width: max(80, win.bounds.width - side * 2), height: h)

        if abs(host.frame.origin.y - frame.origin.y) > 0.5
            || abs(host.frame.width - frame.width) > 0.5 {
            host.frame = frame
        } else if host.superview == nil {
            host.frame = frame
            win.addSubview(host)
        }

        let prefs = GlassPreferences.shared
        _ = GlassBubbleKit.installBubble(
            into: host,
            tag: GlassBubbleKit.dockTag,
            frame: host.bounds,
            style: prefs.style,
            intensity: max(0.75, prefs.intensity),
            opacity: max(0.92, prefs.opacity)
        )

        if host.superview === win, win.subviews.last !== host {
            win.bringSubviewToFront(host)
        }
    }

    private func removeWindowFallback() {
        windowDockHost?.removeFromSuperview()
        for w in GlassAppSupport.allWindows() {
            w.viewWithTag(Self.windowHostTag)?.removeFromSuperview()
        }
        windowDockHost = nil
        usingWindowFallback = false
    }

    private func keyWindow() -> UIWindow? {
        let wins = GlassAppSupport.allWindows()
        if let k = wins.first(where: { $0.isKeyWindow && !$0.isHidden }) { return k }
        return wins.first(where: { !$0.isHidden && $0.bounds.width > 100 && $0.rootViewController != nil })
    }

    // MARK: - Items + selection morph

    /// Collect real tab icons/buttons (not glass plates).
    private func collectTabItems(in bar: UIView) -> [UIView] {
        var items: [UIView] = []
        for sub in bar.subviews {
            if isGlassTag(sub.tag) { continue }
            let sn = NSStringFromClass(type(of: sub)).lowercased()
            // Skip backgrounds / effects
            if sn.contains("background") || sn.contains("visualeffect") || sn.contains("blur") { continue }
            if sn.contains("_uitabbar") && sn.contains("background") { continue }

            let isItem =
                sn.contains("tabbarbutton")
                || sn.contains("uitabbarbutton")
                || sn.contains("igtab")
                || (sn.contains("button") && sub.bounds.width < 100)
                || (sub is UIControl && sub.bounds.width > 12 && sub.bounds.width < 100)
                || (sn.contains("item") && sub.bounds.width < 100)

            guard isItem else { continue }
            let f = sub.frame
            guard f.width > 10, f.height > 10, f.width < 120, f.height < 90 else { continue }
            // Prefer visible, non-hidden
            if sub.isHidden || sub.alpha < 0.05 { continue }
            items.append(sub)
        }
        // Left → right
        items.sort { $0.frame.minX < $1.frame.minX }
        return items
    }

    private func isGlassTag(_ tag: Int) -> Bool {
        tag == GlassBubbleKit.dockTag
            || tag == GlassBubbleKit.selectedTag
            || tag == GlassBubbleKit.plateTag
            || (tag >= GlassBubbleKit.navBubbleTag && tag < GlassBubbleKit.navBubbleTag &+ 32)
            || (tag >= 0x4747_0000 && tag <= 0x4747_FFFF)
    }

    /// Evenly space icons inside the floating pill; keep hit targets on real controls.
    private func alignItems(in bar: UIView, dock: CGRect) {
        let items = collectTabItems(in: bar)
        guard items.count >= 2 else {
            // Fallback: only vertical-center whatever we find
            let midY = dock.midY
            for sub in items {
                var f = sub.frame
                f.origin.y = midY - f.height / 2
                sub.frame = f
                sub.isUserInteractionEnabled = true
            }
            return
        }

        let count = items.count
        let inset: CGFloat = 10
        let usable = max(40, dock.width - inset * 2)
        let slot = usable / CGFloat(count)
        let midY = dock.midY

        for (i, sub) in items.enumerated() {
            var f = sub.frame
            // Preserve intrinsic size, center in slot
            let w = min(max(f.width, 28), slot - 4)
            let h = min(max(f.height, 28), dock.height - 6)
            f.size = CGSize(width: w, height: h)
            f.origin.x = dock.minX + inset + slot * CGFloat(i) + (slot - w) / 2
            f.origin.y = midY - h / 2
            sub.frame = f
            sub.isUserInteractionEnabled = true
            // Ensure glass never eats touches
            sub.isExclusiveTouch = false
        }
    }

    private func updateSelectedBubble(in bar: UIView, dock: CGRect) {
        let prefs = GlassPreferences.shared
        let items = collectTabItems(in: bar)
        guard !items.isEmpty else {
            bar.viewWithTag(GlassBubbleKit.selectedTag)?.isHidden = true
            return
        }

        var selected: UIView?
        for (i, sub) in items.enumerated() {
            let ctrl = sub as? UIControl
            if ctrl?.isSelected == true || ctrl?.isHighlighted == true {
                selected = sub
                lastSelectedIndex = i
            }
        }
        if selected == nil {
            let idx = min(max(0, lastSelectedIndex), items.count - 1)
            selected = items[idx]
            lastSelectedIndex = idx
        }
        guard let target = selected else {
            bar.viewWithTag(GlassBubbleKit.selectedTag)?.isHidden = true
            return
        }

        // Lens follows icon bounds, clamped inside dock
        let pad: CGFloat = 6
        var f = target.frame.insetBy(dx: -pad, dy: -pad)
        f.size.width = max(f.width, 36)
        f.size.height = max(f.height, 36)
        f.origin.x = max(dock.minX + 3, min(f.origin.x, dock.maxX - f.width - 3))
        f.origin.y = max(dock.minY + 2, min(f.origin.y, dock.maxY - f.height - 2))

        let bubble = GlassBubbleKit.installSelectedLens(
            into: bar, frame: f, intensity: max(0.82, prefs.intensity)
        )
        // Glass never steals taps
        bubble.isUserInteractionEnabled = false

        let dx = abs(bubble.frame.midX - f.midX)
        if dx > 1.5 {
            UIView.animate(
                withDuration: 0.40,
                delay: 0,
                usingSpringWithDamping: 0.74,
                initialSpringVelocity: 0.5,
                options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseInOut]
            ) {
                bubble.frame = f
            }
        } else {
            bubble.frame = f
        }
        bubble.isHidden = false
        bubble.alpha = 1

        // Icons always above plate + lens
        if let plate = bar.viewWithTag(GlassBubbleKit.dockTag) {
            bar.insertSubview(bubble, aboveSubview: plate)
        }
        for sub in items {
            bar.bringSubviewToFront(sub)
        }
    }

    private func setCollapsed(_ collapsed: Bool) {
        guard dockCollapsed != collapsed else { return }
        dockCollapsed = collapsed
        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.3,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            if self.usingWindowFallback {
                self.installWindowFloatingDock()
            } else if let bar = self.lastBar {
                self.installOnBar(bar)
            }
        }
    }
}
