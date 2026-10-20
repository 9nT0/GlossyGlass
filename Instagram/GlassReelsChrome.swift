import UIKit

@objc public final class GlassReelsChrome: NSObject {
    @objc public static let shared = GlassReelsChrome()

    @objc public func apply(in window: UIView) {
        let p = GlassPreferences.shared
        guard p.styleReels else { return }

        let reels = IGLocator.shared.findViews(classContains: "reel", in: window)
            + IGLocator.shared.findViews(classContains: "clips", in: window)

        for v in reels {
            let n = NSStringFromClass(type(of: v)).lowercased()
            if n.contains("action") || n.contains("button") || n.contains("toolbar") || n.contains("footer") || n.contains("sidebar") {
                if v.bounds.height > 28 && v.bounds.height < 130 {
                    GlassMaterial.shared.apply(to: v, style: .soft, corner: 14)
                    if p.animations { GlassAnimations.shared.attachPress(to: v) }
                }
            }
        }

        let stories = IGLocator.shared.findViews(classContains: "story", in: window)
            + IGLocator.shared.findViews(classContains: "stories", in: window)
        for v in stories where p.animations && (v is UIControl || v is UIButton) {
            GlassAnimations.shared.attachPress(to: v)
        }

        let viewers = IGLocator.shared.findViews(classContains: "viewer", in: window)
            + IGLocator.shared.findViews(classContains: "playback", in: window)
        for v in viewers where v.bounds.height > 34 && v.bounds.height < 95 {
            GlassMaterial.shared.apply(to: v, style: .soft, corner: 0)
        }
    }
}
