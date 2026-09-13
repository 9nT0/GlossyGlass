import UIKit

/// Registry of what may receive GG chrome. Content is never chrome.
/// Claim rule: neutralize stock fills so IG never wins a full frame before GG owns look.
@objc public final class GlassChromeShield: NSObject {

    @objc public static let shared = GlassChromeShield()
    private var lastArm: TimeInterval = 0

    // MARK: - Allow / ban

    @objc public static func isAllowedChrome(_ view: UIView) -> Bool {
        if GlassMediaExclusion.shouldSkipGlass(for: view) { return false }

        let n = NSStringFromClass(type(of: view)).lowercased()
        let label = (view.accessibilityLabel ?? "").lowercased()
        let blob = n + " " + label

        // Hard content bans — never glass these
        let banned = [
            "username", "caption", "comment", "messagecell", "messagetext",
            "photoview", "imageview", "storycanvas", "reelcanvas", "postbody",
            "feeditem", "collectionviewcell", "tableviewcell", "textview",
            "uilabel", "avplayer", "videoplayer", "storyviewer"
        ]
        if banned.contains(where: { blob.contains($0) }) { return false }

        // Explicit chrome allow
        if view is UITabBar || n.contains("igtabbar") { return true }
        if view is UINavigationBar || n.contains("ignavigationbar") { return true }
        if n.contains("composer") || n.contains("inputtoolbar") || n.contains("messageinput")
            || n.contains("chatbar") { return true }
        if n.contains("reels") && (n.contains("action") || n.contains("toolbar") || n.contains("chrome")
            || n.contains("engagement")) { return true }
        if n.contains("profile") && (n.contains("action") || n.contains("header") || n.contains("toolbar")) {
            return true
        }
        if n.contains("search") && (n.contains("bar") || n.contains("chrome") || n.contains("header")) {
            return true
        }
        return false
    }

    // MARK: - Neutralize stock

    @objc public func neutralizeStock(_ view: UIView) {
        guard Self.isAllowedChrome(view) else { return }
        GlassMaterialEngine.shared.neutralizeStockChrome(view)
    }

    @objc public func armEarly() {
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastArm < 0.15 { return }
        lastArm = now
        for w in GlassAppSupport.allWindows() {
            walk(w, depth: 0)
        }
    }

    private func walk(_ view: UIView, depth: Int) {
        guard depth < 10 else { return }
        let n = NSStringFromClass(type(of: view)).lowercased()

        if view is UITabBar || n.contains("igtabbar")
            || view is UINavigationBar || n.contains("ignavigationbar") {
            neutralizeStock(view)
        }

        // Skip heavy content trees
        if view is UICollectionView || view is UITableView { return }
        if GlassMediaExclusion.matches(view) { return }

        for s in view.subviews {
            walk(s, depth: depth + 1)
        }
    }
}
