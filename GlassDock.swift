import UIKit

/// iOS 26 floating pill dock — single presentation path, no double glass.
/// - Prefer painting on real / IG tab bar
/// - Window fallback ONLY when no bar is found (avoids stacked pills / hitches)
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
            // Real chrome found — paint there, remove window fallback if any
            removeWindowFallback()
            usingWindowFallback = false
            installOnBar(bar)
            NSLog("[GlossyGlass] Dock on bar")
        } else {
            // No bar yet — soft window pill only (no interaction steal)
            usingWindowFallback = true
            installWindowFloatingDock()
            NSLog("[GlossyGlass] Dock window fallback")
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
        if delta > 10 { setCollapsed(true) }
        else if delta < -10 { setCollapsed(false) }
    }

    @objc public func settle() { setCollapsed(false) }

    // MARK: - Find

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
        if b.width > UIScreen.main.bounds.width * 0.85,
           b.height >= 40, b.height <= 100 {
            let originY: CGFloat
            if let w = view.window {
                originY = view.convert(CGPoint.zero, to: w).y
            } else {
                originY = view.convert(CGPoint.zero, to: nil).y
            }
            if originY + b.height > screenH - 130 {
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

    // MARK: - On bar (preferred)

    private func installOnBar(_ bar: UIView) {
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastLayout < 0.06 { return }
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
        let side: CGFloat = 16
        let baseH: CGFloat = dockCollapsed ? 40 : 54
        let bottomPad: CGFloat = max(6, bar.safeAreaInsets.bottom > 0 ? 8 : 10)
        let y = max(2, b.height - baseH - bottomPad)
        let dockFrame = CGRect(x: side, y: y, width: max(80, b.width - side * 2), height: baseH)

        let plate = GlassBubbleKit.installBubble(
            into: bar,
            tag: GlassBubbleKit.dockTag,
            frame: dockFrame,
            style: prefs.style,
            intensity: max(0.75, prefs.intensity),
            opacity: max(0.92, prefs.opacity)
        )
        applyPlateStyle(plate, height: baseH, intensity: prefs.intensity)

        alignItems(in: bar, dock: dockFrame)
        updateSelectedBubble(in: bar, dock: dockFrame)

        // Icons above glass — once, cheap
        for sub in bar.subviews {
            if sub.tag == GlassBubbleKit.dockTag || sub.tag == GlassBubbleKit.selectedTag { continue }
            bar.bringSubviewToFront(sub)
        }
        if let sel = bar.viewWithTag(GlassBubbleKit.selectedTag) {
            bar.insertSubview(sel, aboveSubview: plate)
        }
    }

    // MARK: - Window fallback (only when no bar)

    private func installWindowFloatingDock() {
        guard let win = keyWindow() else { return }

        let host: UIView
        if let existing = win.viewWithTag(Self.windowHostTag) {
            host = existing
        } else {
            host = UIView()
            host.tag = Self.windowHostTag
            host.isUserInteractionEnabled = false // never block IG taps
            host.backgroundColor = .clear
            host.isAccessibilityElement = false
            win.addSubview(host)
        }
        windowDockHost = host

        let safeBottom = win.safeAreaInsets.bottom
        let side: CGFloat = 20
        let h: CGFloat = dockCollapsed ? 42 : 56
        let y = win.bounds.height - safeBottom - h - 8
        let frame = CGRect(x: side, y: y, width: max(80, win.bounds.width - side * 2), height: h)

        // Avoid layout thrash if unchanged
        if abs(host.frame.origin.y - frame.origin.y) > 0.5
            || abs(host.frame.width - frame.width) > 0.5 {
            host.frame = frame
        } else if host.superview == nil {
            host.frame = frame
            win.addSubview(host)
        }

        let prefs = GlassPreferences.shared
        let plate = GlassBubbleKit.installBubble(
            into: host,
            tag: GlassBubbleKit.dockTag,
            frame: host.bounds,
            style: prefs.style,
            intensity: max(0.78, prefs.intensity),
            opacity: max(0.94, prefs.opacity)
        )
        applyPlateStyle(plate, height: h, intensity: prefs.intensity)

        // Keep above content but don't fight every frame
        if host.superview === win, win.subviews.last !== host {
            win.bringSubviewToFront(host)
        }
    }

    private func removeWindowFallback() {
        if let host = windowDockHost {
            host.removeFromSuperview()
        }
        // Also clear any orphan hosts on windows
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

    private func applyPlateStyle(_ plate: UIView, height: CGFloat, intensity: CGFloat) {
        plate.layer.cornerRadius = height * 0.48
        if #available(iOS 13.0, *) { plate.layer.cornerCurve = .continuous }
        plate.layer.shadowColor = UIColor.black.cgColor
        plate.layer.shadowOpacity = Float(0.28 * max(0.5, intensity))
        plate.layer.shadowRadius = 14
        plate.layer.shadowOffset = CGSize(width: 0, height: 5)
        plate.layer.masksToBounds = false
        plate.clipsToBounds = true
        plate.isUserInteractionEnabled = false
        plate.alpha = 1
        plate.isHidden = false
    }

    // MARK: - Items / selection

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
            let highlighted = ctrl?.isSelected == true || ctrl?.isHighlighted == true
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
        f.origin.x = max(dock.minX + 4, min(f.origin.x, dock.maxX - f.width - 4))
        f.origin.y = max(dock.minY + 2, min(f.origin.y, dock.maxY - f.height - 2))

        let bubble = GlassBubbleKit.installSelectedLens(
            into: bar, frame: f, intensity: max(0.85, prefs.intensity)
        )
        // Only animate if frame actually moved
        if abs(bubble.frame.midX - f.midX) > 1 {
            UIView.animate(withDuration: 0.30, delay: 0, usingSpringWithDamping: 0.80,
                           initialSpringVelocity: 0.35, options: [.allowUserInteraction, .beginFromCurrentState]) {
                bubble.frame = f
            }
        } else {
            bubble.frame = f
        }
        bubble.isHidden = false
        bubble.alpha = 1
    }

    private func setCollapsed(_ collapsed: Bool) {
        guard dockCollapsed != collapsed else { return }
        dockCollapsed = collapsed
        UIView.animate(withDuration: 0.26, delay: 0, options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]) {
            if self.usingWindowFallback {
                self.installWindowFloatingDock()
            } else if let bar = self.lastBar {
                self.installOnBar(bar)
            }
        }
    }
}
