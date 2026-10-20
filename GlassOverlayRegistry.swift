import UIKit

/// Tagged overlay registry + global sweep to kill stray plates on content.
@objc public final class GlassOverlayRegistry: NSObject {

    @objc public static let shared = GlassOverlayRegistry()

    private var knownTags: Set<Int> = [
        GlassBubbleKit.dockTag,
        GlassBubbleKit.selectedTag,
        GlassBubbleKit.navBubbleTag,
        GlassBubbleKit.plateTag,
        GlassBubbleKit.reelsChromeTag,
        GlassBubbleKit.dmChromeTag,
        GlassBubbleKit.presentationTag,
        0x4747_4358, // context
        0x4747_4359,
        0x4747_494E, // instants
        0x4747_5748  // window dock host
    ]

    @objc public func register(tag: Int) {
        knownTags.insert(tag)
    }

    @objc public func resolve(tag: Int, in host: UIView, create: () -> UIView) -> UIView {
        if let existing = host.viewWithTag(tag) { return existing }
        let v = create()
        v.tag = tag
        host.insertSubview(v, at: 0)
        knownTags.insert(tag)
        return v
    }

    @objc public func clearAll(in host: UIView) {
        var toRemove: [UIView] = []
        collect(host, depth: 0, into: &toRemove)
        for v in toRemove { v.removeFromSuperview() }
    }

    private func collect(_ view: UIView, depth: Int, into list: inout [UIView]) {
        guard depth < 18 else { return }
        if isGGTag(view.tag) { list.append(view) }
        for s in view.subviews {
            collect(s, depth: depth + 1, into: &list)
        }
    }

    private func isGGTag(_ tag: Int) -> Bool {
        knownTags.contains(tag)
            || (tag >= GlassBubbleKit.navBubbleTag && tag < GlassBubbleKit.navBubbleTag &+ 32)
            || (tag >= 0x4747_0000 && tag <= 0x4747_FFFF)
    }

    /// Strip GG plates that landed on content / headers / cells. Keep dock + nav bubbles on real chrome.
    @objc public func sweepContentOverlays() {
        for w in GlassAppSupport.allWindows() {
            sweep(w, depth: 0, inChrome: false)
        }
    }

    private func sweep(_ view: UIView, depth: Int, inChrome: Bool) {
        guard depth < 16 else { return }
        let n = NSStringFromClass(type(of: view)).lowercased()
        let chromeHere = inChrome
            || view is UITabBar || view is UINavigationBar
            || n.contains("igtabbar") || n.contains("ignavigationbar")
            || n.contains("tabbar") && view.bounds.height < 100
            || view.tag == 0x4747_5748 // our window dock host

        // Content surfaces — remove all GG tags
        let isContent =
            view is UICollectionViewCell || view is UITableViewCell
            || view is UILabel || view is UITextView || view is UITextField
            || view is UIImageView && view.bounds.width > 48
            || n.contains("username") || n.contains("caption") || n.contains("messagecell")
            || n.contains("feeditem") || n.contains("threadname") || n.contains("titleview")
            || n.contains("storycanvas") || n.contains("reelcanvas") || n.contains("avplayer")

        if isContent {
            for sub in view.subviews where isGGTag(sub.tag) {
                sub.removeFromSuperview()
            }
            // Don't recurse into media trees deeply
            if view is UICollectionViewCell || view is UITableViewCell { return }
        }

        // Full-width plates near top (header overlays) — kill unless nav chrome
        if !chromeHere, isGGTag(view.tag), view.bounds.width > 120 {
            if let win = view.window {
                let y = view.convert(CGPoint.zero, to: win).y
                if y < win.bounds.height * 0.22 {
                    view.removeFromSuperview()
                    return
                }
            }
        }

        for s in view.subviews {
            sweep(s, depth: depth + 1, inChrome: chromeHere)
        }
    }

    @objc public func dedupe(in host: UIView, tag: Int) {
        var found: UIView?
        var extras: [UIView] = []
        walkDedupe(host, tag: tag, found: &found, extras: &extras, depth: 0)
        for e in extras { e.removeFromSuperview() }
    }

    private func walkDedupe(_ view: UIView, tag: Int, found: inout UIView?, extras: inout [UIView], depth: Int) {
        guard depth < 16 else { return }
        if view.tag == tag {
            if found == nil { found = view } else { extras.append(view) }
        }
        for s in view.subviews {
            walkDedupe(s, tag: tag, found: &found, extras: &extras, depth: depth + 1)
        }
    }
}
