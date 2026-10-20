import UIKit

@objc public final class GlassDMChrome: NSObject {
    @objc public static let shared = GlassDMChrome()

    @objc public func apply(in window: UIView) {
        let p = GlassPreferences.shared
        guard p.styleDMs else { return }

        let headers = IGLocator.shared.findViews(classContains: "threadheader", in: window)
            + IGLocator.shared.findViews(classContains: "dmheader", in: window)
            + IGLocator.shared.findViews(classContains: "inboxheader", in: window)

        for h in headers {
            guard !IGLocator.shared.isContent(h) else { continue }
            if h.bounds.height > 36 && h.bounds.height < 120 {
                GlassMaterial.shared.apply(to: h, style: .standard, corner: 0)
            }
        }

        // Strip glass from message lists (fixes blank chat)
        let lists = IGLocator.shared.findViews(classContains: "threadview", in: window)
            + IGLocator.shared.findViews(classContains: "messagecell", in: window)
            + IGLocator.shared.findViews(classContains: "directthread", in: window)
            + IGLocator.shared.findViews(classContains: "collectionview", in: window)
        for v in lists {
            if v is UICollectionView || v is UITableView || IGLocator.shared.isContent(v) {
                GlassMaterial.shared.remove(from: v)
            }
        }
    }
}
