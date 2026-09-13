import UIKit

/// iOS-26 nav: CLEAR bar background, small glass capsules on controls only.
@objc public final class GlassNavChrome: NSObject {

    @objc public static let shared = GlassNavChrome()

    @objc public func apply() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode, prefs.styleNavigationBar else { return }
        for w in GlassAppSupport.allWindows() {
            walk(w, depth: 0)
        }
    }

    @objc public func apply(to bar: UINavigationBar) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, prefs.styleNavigationBar else { return }
        if GlassMediaExclusion.shouldSkipGlass(for: bar) { return }

        // CLEAR full bar
        GlassMaterialEngine.shared.neutralizeStockChrome(bar)
        GlassNavigationHelper.applyNavigationBarStyle(to: bar)

        // Remove any full-width plate we may have installed earlier
        if let full = bar.viewWithTag(GlassBubbleKit.plateTag) {
            full.removeFromSuperview()
        }
        // Don't install full-width material
        styleControlBubbles(in: bar)
    }

    private func walk(_ view: UIView, depth: Int) {
        guard depth < 12 else { return }
        if let nav = view as? UINavigationBar {
            apply(to: nav)
        }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if n.contains("ignavigationbar"), view is UIView {
            // treat as nav host
            styleControlBubbles(in: view)
            view.backgroundColor = .clear
            view.isOpaque = false
        }
        for s in view.subviews { walk(s, depth: depth + 1) }
    }

    private func styleControlBubbles(in bar: UIView) {
        let prefs = GlassPreferences.shared
        // Left/right bar button items → small capsules around control frames
        var bubbleIndex = 0
        for sub in bar.subviews {
            let sn = NSStringFromClass(type(of: sub)).lowercased()
            // Skip title labels / large content
            if sub is UILabel { continue }
            if sn.contains("contentview") || sn.contains("prompt") { continue }
            if sn.contains("button") || sub is UIControl || sn.contains("barbutton") {
                let f = sub.frame
                guard f.width > 12, f.height > 12, f.width < 120, f.height < 56 else { continue }
                // Expand slightly for bubble
                let pad: CGFloat = 4
                let bubbleFrame = f.insetBy(dx: -pad, dy: -pad)
                let tag = GlassBubbleKit.navBubbleTag &+ bubbleIndex
                bubbleIndex += 1
                let b = GlassBubbleKit.installBubble(
                    into: bar,
                    tag: tag,
                    frame: bubbleFrame,
                    style: prefs.style,
                    intensity: max(0.55, prefs.intensity),
                    opacity: max(0.85, prefs.opacity)
                )
                // Keep control above bubble
                bar.insertSubview(b, belowSubview: sub)
            }
        }
    }
}
