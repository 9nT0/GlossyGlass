import UIKit

/// DM header + composer glass only. Never covers message text or media.
@objc public final class GlassDMChrome: NSObject {

    @objc public static let shared = GlassDMChrome()
    private var lastApply: TimeInterval = 0

    @objc public func apply() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }

        let now = CFAbsoluteTimeGetCurrent()
        if now - lastApply < 0.12 { return }
        lastApply = now

        for w in GlassAppSupport.allWindows() {
            walk(w, depth: 0)
        }
    }

    private func walk(_ view: UIView, depth: Int) {
        guard depth < 14 else { return }
        if GlassMediaExclusion.shouldSkipGlass(for: view) { return }

        let n = NSStringFromClass(type(of: view)).lowercased()

        if n.contains("composer") || n.contains("inputtoolbar")
            || n.contains("messageinput") || n.contains("chatbar")
            || n.contains("textinputbar") {
            styleComposer(view)
        }

        // Don't walk into message cells / media
        if n.contains("messagecell") || n.contains("bubble") || n.contains("cellcontent") {
            return
        }
        if view is UICollectionView || view is UITableView {
            // Still check direct subviews that might be toolbars outside cells
            for s in view.subviews where !(s is UICollectionViewCell || s is UITableViewCell) {
                walk(s, depth: depth + 1)
            }
            return
        }

        for s in view.subviews {
            walk(s, depth: depth + 1)
        }
    }

    private func styleComposer(_ view: UIView) {
        if GlassMediaExclusion.shouldSkipGlass(for: view) { return }

        // Update existing blur rather than stacking
        if let fx = view as? UIVisualEffectView {
            fx.effect = GlassMaterialEngine.shared.blurEffect(
                style: GlassPreferences.shared.style, dark: true, intensity: 0.65
            )
            return
        }

        view.backgroundColor = .clear
        view.isOpaque = false

        let prefs = GlassPreferences.shared
        let inset = view.bounds.insetBy(dx: 6, dy: 4)
        guard inset.width > 40, inset.height > 20 else { return }

        let b = GlassBubbleKit.installBubble(
            into: view,
            tag: GlassBubbleKit.dmChromeTag,
            frame: inset,
            style: prefs.style,
            intensity: max(0.55, prefs.intensity),
            opacity: max(0.88, prefs.opacity)
        )
        b.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        b.layer.cornerRadius = min(22, inset.height * 0.48)
        if #available(iOS 13.0, *) { b.layer.cornerCurve = .continuous }

        for sub in view.subviews where sub.tag != GlassBubbleKit.dmChromeTag {
            view.bringSubviewToFront(sub)
        }
    }
}
