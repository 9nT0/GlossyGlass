import UIKit

@objc public final class GlassFeedChrome: NSObject {
    @objc public static let shared = GlassFeedChrome()

    @objc public func apply(in window: UIView) {
        let p = GlassPreferences.shared
        guard p.styleFeed else { return }

        let candidates = IGLocator.shared.findViews(classContains: "action", in: window)
            + IGLocator.shared.findViews(classContains: "toolbar", in: window)
            + IGLocator.shared.findViews(classContains: "footer", in: window)
            + IGLocator.shared.findViews(classContains: "buttonbar", in: window)

        for v in candidates {
            guard !IGLocator.shared.isContent(v) else { continue }
            if v.bounds.height > 28 && v.bounds.height < 80 {
                GlassMaterial.shared.apply(to: v, style: .soft, corner: 12)
                if p.animations { GlassAnimations.shared.attachPress(to: v) }
            }
        }
        for v in IGLocator.shared.findViews(classContains: "feeditem", in: window)
            + IGLocator.shared.findViews(classContains: "mediaview", in: window) {
            GlassMaterial.shared.remove(from: v)
        }
    }
}
