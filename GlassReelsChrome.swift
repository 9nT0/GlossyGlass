import UIKit

/// Reels chrome: glass only on side/bottom controls. Video stays pure content.
@objc public final class GlassReelsChrome: NSObject {

    @objc public static let shared = GlassReelsChrome()
    private var lastApply: TimeInterval = 0
    private let sideTagBase = 0x4747_5253 // GGRS

    @objc public func apply() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        guard GlassSurfaceRouter.shared.activeSurface == .reels else { return }

        let now = CFAbsoluteTimeGetCurrent()
        if now - lastApply < 0.12 { return }
        lastApply = now

        for w in GlassAppSupport.allWindows() {
            walk(w, depth: 0, index: 0)
        }
    }

    @discardableResult
    private func walk(_ view: UIView, depth: Int, index: Int) -> Int {
        guard depth < 14 else { return index }
        if GlassMediaExclusion.shouldSkipGlass(for: view) { return index }

        let n = NSStringFromClass(type(of: view)).lowercased()
        var idx = index

        // Side action stacks (like / comment / share)
        let isSideAction = (n.contains("action") || n.contains("toolbar") || n.contains("buttonstack")
            || n.contains("engagement") || n.contains("reaction"))
            && (n.contains("reel") || n.contains("sundial") || n.contains("clips")
                || view.bounds.width < 80)

        // Bottom caption / audio chrome
        let isBottomChrome = (n.contains("caption") || n.contains("audio") || n.contains("music")
            || n.contains("attribution"))
            && view.bounds.height < 120
            && view.bounds.width > 100

        if isSideAction {
            styleControl(view, tag: sideTagBase &+ idx)
            idx += 1
        } else if isBottomChrome {
            styleCaptionPill(view)
        }

        // Don't descend into large media surfaces
        if view.bounds.height > UIScreen.main.bounds.height * 0.5,
           (n.contains("player") || n.contains("video") || n.contains("canvas")) {
            return idx
        }
        if view is UICollectionView || view is UITableView {
            return idx
        }

        for s in view.subviews {
            idx = walk(s, depth: depth + 1, index: idx)
            if idx > 12 { break }
        }
        return idx
    }

    private func styleControl(_ view: UIView, tag: Int) {
        let prefs = GlassPreferences.shared
        let f = view.bounds
        guard f.width > 20, f.height > 20, f.width < 90, f.height < 90 else { return }

        // Round glass behind icon
        let size = min(f.width, f.height)
        let frame = CGRect(
            x: (f.width - size) * 0.5,
            y: (f.height - size) * 0.5,
            width: size,
            height: size
        )
        let b = GlassBubbleKit.installBubble(
            into: view,
            tag: tag,
            frame: frame,
            style: "clear",
            intensity: min(0.55, prefs.intensity),
            opacity: min(0.75, prefs.opacity)
        )
        b.layer.cornerRadius = size * 0.5
        for sub in view.subviews where sub.tag != tag {
            view.bringSubviewToFront(sub)
        }
    }

    private func styleCaptionPill(_ view: UIView) {
        let prefs = GlassPreferences.shared
        view.backgroundColor = .clear
        let b = GlassBubbleKit.installBubble(
            into: view,
            tag: GlassBubbleKit.reelsChromeTag,
            frame: view.bounds.insetBy(dx: 4, dy: 2),
            style: "clear",
            intensity: min(0.5, prefs.intensity),
            opacity: min(0.7, prefs.opacity)
        )
        b.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        b.layer.cornerRadius = min(16, view.bounds.height * 0.4)
        for sub in view.subviews where sub.tag != GlassBubbleKit.reelsChromeTag {
            view.bringSubviewToFront(sub)
        }
    }
}
