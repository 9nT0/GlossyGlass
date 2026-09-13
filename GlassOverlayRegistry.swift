import UIKit

/// Create-or-update overlays by stable tag. Prevents stacked blur/plate boxes.
@objc public final class GlassOverlayRegistry: NSObject {

    @objc public static let shared = GlassOverlayRegistry()

    private var knownTags: Set<Int> = [
        GlassBubbleKit.dockTag,
        GlassBubbleKit.selectedTag,
        GlassBubbleKit.navBubbleTag,
        GlassBubbleKit.plateTag,
        GlassBubbleKit.reelsChromeTag,
        GlassBubbleKit.dmChromeTag,
        GlassBubbleKit.presentationTag
    ]

    @objc public func register(tag: Int) {
        knownTags.insert(tag)
    }

    /// Returns existing view with tag, or creates via factory once.
    @objc public func resolve(
        tag: Int,
        in host: UIView,
        create: () -> UIView
    ) -> UIView {
        if let existing = host.viewWithTag(tag) {
            return existing
        }
        let v = create()
        v.tag = tag
        host.insertSubview(v, at: 0)
        knownTags.insert(tag)
        return v
    }

    /// Remove every GG-tagged overlay under host (safe mode / reset).
    @objc public func clearAll(in host: UIView) {
        var toRemove: [UIView] = []
        collect(host, depth: 0, into: &toRemove)
        for v in toRemove {
            v.removeFromSuperview()
        }
    }

    private func collect(_ view: UIView, depth: Int, into list: inout [UIView]) {
        guard depth < 16 else { return }
        if knownTags.contains(view.tag)
            || (view.tag >= GlassBubbleKit.navBubbleTag && view.tag < GlassBubbleKit.navBubbleTag &+ 32)
            || (view.tag >= 0x4747_5253 && view.tag < 0x4747_5253 &+ 16) {
            list.append(view)
        }
        for s in view.subviews {
            collect(s, depth: depth + 1, into: &list)
        }
    }

    /// Deduplicate: if multiple views share a tag, keep the first, remove rest.
    @objc public func dedupe(in host: UIView, tag: Int) {
        var found: UIView?
        var extras: [UIView] = []
        walkDedupe(host, tag: tag, found: &found, extras: &extras, depth: 0)
        for e in extras { e.removeFromSuperview() }
    }

    private func walkDedupe(_ view: UIView, tag: Int, found: inout UIView?, extras: inout [UIView], depth: Int) {
        guard depth < 16 else { return }
        if view.tag == tag {
            if found == nil { found = view }
            else { extras.append(view) }
        }
        for s in view.subviews {
            walkDedupe(s, tag: tag, found: &found, extras: &extras, depth: depth + 1)
        }
    }
}
