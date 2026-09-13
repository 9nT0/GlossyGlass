import UIKit

/// Registry of what may receive GG chrome. Content is never chrome.
@objc public final class GlassChromeShield: NSObject {

    @objc public static let shared = GlassChromeShield()

    @objc public static func isAllowedChrome(_ view: UIView) -> Bool {
        if GlassMediaExclusion.shouldSkipGlass(for: view) { return false }
        let n = NSStringFromClass(type(of: view)).lowercased()
        let label = (view.accessibilityLabel ?? "").lowercased()
        let blob = n + " " + label

        // Hard content bans
        let banned = [
            "username", "caption", "comment", "messagecell", "messagetext",
            "photoview", "imageview", "storycanvas", "reelcanvas", "postbody",
            "feeditem", "collectionviewcell", "tableviewcell"
        ]
        if banned.contains(where: { blob.contains($0) }) { return false }

        if view is UITabBar || n.contains("igtabbar") { return true }
        if view is UINavigationBar || n.contains("ignavigationbar") { return true }
        if n.contains("composer") || n.contains("inputtoolbar") || n.contains("messageinput") { return true }
        if n.contains("reels") && (n.contains("action") || n.contains("toolbar") || n.contains("chrome")) { return true }
        return false
    }

    @objc public func neutralizeStock(_ view: UIView) {
        guard Self.isAllowedChrome(view) else { return }
        GlassMaterialEngine.shared.neutralizeStockChrome(view)
    }

    @objc public func armEarly() {
        for w in GlassAppSupport.allWindows() {
            walk(w, depth: 0)
        }
    }

    private func walk(_ view: UIView, depth: Int) {
        guard depth < 10 else { return }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if view is UITabBar || n.contains("igtabbar") || view is UINavigationBar || n.contains("ignavigationbar") {
            neutralizeStock(view)
        }
        for s in view.subviews { walk(s, depth: depth + 1) }
    }
}
