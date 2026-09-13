import UIKit

/// Messages surface: glass ONLY the bottom composer / input toolbar.
/// Never glass the navigation title, username, avatar, or thread name.
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
            // Strip any GG plate sitting on headers / name labels first
            stripBadOverlays(w, depth: 0)
            // Composer only
            if let composer = findComposer(in: w, depth: 0) {
                styleComposer(composer)
            }
        }
    }

    // MARK: - Strip name/header overlays

    private func stripBadOverlays(_ view: UIView, depth: Int) {
        guard depth < 16 else { return }
        let n = NSStringFromClass(type(of: view)).lowercased()
        let label = (view.accessibilityLabel ?? "").lowercased()
        let blob = n + " " + label

        let isHeaderish =
            blob.contains("navbar") || blob.contains("navigationbar")
            || blob.contains("titleview") || blob.contains("username")
            || blob.contains("threadname") || blob.contains("displayname")
            || blob.contains("header") || blob.contains("navtitle")
            || blob.contains("directthread") && blob.contains("header")

        // Remove GG-tagged plates that were incorrectly placed on header/name regions
        if isHeaderish || view is UILabel {
            for sub in view.subviews {
                if isGGTag(sub.tag) {
                    sub.removeFromSuperview()
                }
            }
        }
        // Also remove full-width plates near top of window that aren't dock
        if let win = view.window ?? (view as? UIWindow) {
            let topBand = win.bounds.height * 0.18
            if view.frame.maxY < topBand, view.bounds.width > win.bounds.width * 0.5 {
                for sub in view.subviews where isGGTag(sub.tag) && sub.tag != GlassBubbleKit.navBubbleTag {
                    // Keep small nav bubbles only
                    if sub.bounds.width > 120 {
                        sub.removeFromSuperview()
                    }
                }
            }
        }

        if view is UICollectionViewCell || view is UITableViewCell {
            for sub in view.subviews where isGGTag(sub.tag) {
                sub.removeFromSuperview()
            }
            return
        }
        for s in view.subviews {
            stripBadOverlays(s, depth: depth + 1)
        }
    }

    private func isGGTag(_ tag: Int) -> Bool {
        tag == GlassBubbleKit.dockTag
            || tag == GlassBubbleKit.selectedTag
            || tag == GlassBubbleKit.plateTag
            || tag == GlassBubbleKit.dmChromeTag
            || tag == GlassBubbleKit.reelsChromeTag
            || tag == GlassBubbleKit.presentationTag
            || (tag >= GlassBubbleKit.navBubbleTag && tag < GlassBubbleKit.navBubbleTag &+ 32)
            || (tag >= 0x4747_0000 && tag <= 0x4747_FFFF)
    }

    // MARK: - Composer only

    private func findComposer(in view: UIView, depth: Int) -> UIView? {
        guard depth < 14 else { return nil }
        let n = NSStringFromClass(type(of: view)).lowercased()
        let label = (view.accessibilityLabel ?? "").lowercased()
        let blob = n + " " + label

        // Never treat header as composer
        if blob.contains("navbar") || blob.contains("navigationbar") || blob.contains("titleview") {
            return nil
        }

        let looksComposer =
            (blob.contains("composer") || blob.contains("inputtoolbar")
             || blob.contains("messageinput") || blob.contains("chatbar")
             || blob.contains("textinput") || blob.contains("writebar")
             || blob.contains("igdirect") && blob.contains("input"))
            && view.bounds.height >= 36 && view.bounds.height <= 120
            && view.bounds.width > 160

        if looksComposer {
            // Prefer bottom-of-screen
            if let w = view.window {
                let y = view.convert(CGPoint.zero, to: w).y
                if y > w.bounds.height * 0.55 { return view }
            } else {
                return view
            }
        }

        if view is UICollectionViewCell || view is UITableViewCell { return nil }
        for s in view.subviews {
            if let f = findComposer(in: s, depth: depth + 1) { return f }
        }
        return nil
    }

    private func styleComposer(_ host: UIView) {
        let prefs = GlassPreferences.shared
        // Soft plate behind composer only — inset, not full-bleed over names
        let inset: CGFloat = 8
        let f = host.bounds.insetBy(dx: inset, dy: 4)
        guard f.width > 80, f.height > 28 else { return }

        let plate = GlassBubbleKit.installBubble(
            into: host,
            tag: GlassBubbleKit.dmChromeTag,
            frame: f,
            style: prefs.style,
            intensity: max(0.55, prefs.intensity * 0.9),
            opacity: max(0.75, prefs.opacity * 0.9)
        )
        plate.isUserInteractionEnabled = false
        plate.layer.cornerRadius = min(prefs.cornerRadius, f.height * 0.45)
        // Raise real controls
        for sub in host.subviews {
            if sub.tag == GlassBubbleKit.dmChromeTag { continue }
            host.bringSubviewToFront(sub)
        }
    }
}
