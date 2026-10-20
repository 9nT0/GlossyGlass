import UIKit

/// Home feed action bars, like/comment/share row, story tray edge
@objc public final class GlassFeedChrome: NSObject {
    @objc public static let shared = GlassFeedChrome()

    @objc public func apply(in window: UIView) {
        let p = GlassPreferences.shared
        guard p.styleFeed else { return }

        let feed = IGLocator.shared.findViews(classContains: "feed", in: window)
            + IGLocator.shared.findViews(classContains: "timeline", in: window)
            + IGLocator.shared.findViews(classContains: "mainfeed", in: window)

        for v in feed {
            let n = NSStringFromClass(type(of: v)).lowercased()
            if n.contains("action") || n.contains("toolbar") || n.contains("footer") || n.contains("buttonbar") {
                if v.bounds.height > 30 && v.bounds.height < 90 {
                    GlassMaterial.shared.apply(to: v, style: .soft, corner: 12)
                    if p.animations { GlassAnimations.shared.attachPress(to: v) }
                }
            }
        }

        // Like / comment / share style controls
        let actions = IGLocator.shared.findViews(classContains: "like", in: window)
            + IGLocator.shared.findViews(classContains: "comment", in: window)
            + IGLocator.shared.findViews(classContains: "share", in: window)
            + IGLocator.shared.findViews(classContains: "save", in: window)

        for b in actions where b is UIControl || b is UIButton {
            if p.animations { GlassAnimations.shared.attachPress(to: b) }
            if p.glossyMode {
                b.tintColor = UIColor.white.withAlphaComponent(0.95)
            }
        }
    }
}
