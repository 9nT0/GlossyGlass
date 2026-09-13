import UIKit

/// Content is never chrome. Expand aggressively so names / messages / media stay clean.
@objc public final class GlassMediaExclusion: NSObject {

    @objc public static func matches(_ view: UIView) -> Bool {
        shouldSkipGlass(for: view)
    }

    @objc public static func shouldSkipGlass(for view: UIView) -> Bool {
        if view is UIImageView || view is UILabel || view is UITextView || view is UITextField {
            // Labels/text fields are content unless they are tiny bar labels
            if view is UILabel {
                let f = view.bounds
                // Large title / username style labels = content
                if f.width > 60 || f.height > 22 { return true }
            }
            if view is UITextView || view is UITextField { return true }
            if view is UIImageView, view.bounds.width > 40 { return true }
        }
        if view is UICollectionViewCell || view is UITableViewCell { return true }
        if view is UICollectionView || view is UITableView { return true }

        let n = NSStringFromClass(type(of: view)).lowercased()
        let label = (view.accessibilityLabel ?? "").lowercased()
        let blob = n + " " + label

        let banned = [
            "username", "displayname", "threadname", "navtitle", "titleview",
            "caption", "comment", "messagecell", "messagetext", "messagelabel",
            "photoview", "imageview", "storycanvas", "reelcanvas", "postbody",
            "feeditem", "feedcell", "collectionviewcell", "tableviewcell",
            "avplayer", "videoplayer", "storyviewer", "mediaview",
            "directthread", "inboxcell", "threadcell", "profileheader",
            "uiglass", "visualeffect" // never nest
        ]
        if banned.contains(where: { blob.contains($0) }) { return true }

        // Header regions in messages
        if blob.contains("header") && (blob.contains("message") || blob.contains("direct") || blob.contains("thread")) {
            return true
        }
        return false
    }
}
