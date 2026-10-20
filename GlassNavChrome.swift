import UIKit

/// Small floating control bubbles on navigation — icons stay on top, frames untouched for hit testing.
@objc public final class GlassNavChrome: NSObject {

    @objc public static let shared = GlassNavChrome()

    @objc public func apply() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode, prefs.styleNavigationBar else { return }
        for w in GlassAppSupport.allWindows() {
            if let bar = findNavBar(in: w, depth: 0) {
                apply(to: bar)
            }
        }
    }

    @objc public func apply(to bar: UIView) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode, prefs.styleNavigationBar else { return }
        if GlassMediaExclusion.shouldSkipGlass(for: bar) { return }

        if let nav = bar as? UINavigationBar {
            GlassNavigationHelper.applyNavigationBarStyle(to: nav)
        } else {
            bar.backgroundColor = .clear
            for sub in bar.subviews {
                let sn = NSStringFromClass(type(of: sub)).lowercased()
                if sn.contains("background") || sn.contains("_uinavigationbarbackground") {
                    sub.isHidden = true
                    sub.alpha = 0
                }
            }
        }

        styleControlBubbles(in: bar)
    }

    private func findNavBar(in view: UIView, depth: Int) -> UIView? {
        guard depth < 14 else { return nil }
        if view is UINavigationBar { return view }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if (n.contains("ignavigationbar") || n.contains("navigationbar")),
           view.bounds.height > 28, view.bounds.height < 120 {
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
        var controls: [UIView] = []

        for sub in bar.subviews {
            if bubbleIndex >= maxBubbles { break }
            let sn = NSStringFromClass(type(of: sub)).lowercased()
            if isGG(sub.tag) { continue }
            if sub is UILabel { continue }
            if sn.contains("contentview") || sn.contains("prompt") || sn.contains("title") { continue }
            if sn.contains("background") || sn.contains("visualeffect") { continue }

            let isControl = sn.contains("button") || sub is UIControl || sn.contains("barbutton")
                || sn.contains("uibarbutton") || sn.contains("back")
            let small = sub.bounds.width <= 52 && sub.bounds.height <= 52
            guard isControl || small else { continue }

            let f = sub.frame
            guard f.width > 12, f.height > 12, f.width < 96, f.height < 52 else { continue }
            if sub.isHidden || sub.alpha < 0.05 { continue }
            controls.append(sub)
        }

        for sub in controls {
            if bubbleIndex >= maxBubbles { break }
            // Bubble slightly larger than control — do NOT move the control frame
            let pad: CGFloat = 5
            let bubbleFrame = sub.frame.insetBy(dx: -pad, dy: -pad)
            let tag = GlassBubbleKit.navBubbleTag &+ bubbleIndex
            bubbleIndex += 1

            let b = GlassBubbleKit.installBubble(
                into: bar,
                tag: tag,
                frame: bubbleFrame,
                style: prefs.style,
                intensity: max(0.68, prefs.intensity),
                opacity: max(0.90, prefs.opacity)
            )
            b.isUserInteractionEnabled = false
            // Glass under icon
            bar.insertSubview(b, belowSubview: sub)
            // Keep real control tappable
            sub.isUserInteractionEnabled = true
        }

        // Raise all non-glass controls above bubbles
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
