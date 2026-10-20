import UIKit

@objc public final class GlassProfileChrome: NSObject {
    @objc public static let shared = GlassProfileChrome()

    @objc public func apply(in window: UIView) {
        let p = GlassPreferences.shared
        guard p.styleProfiles else { return }

        let profiles = IGLocator.shared.findViews(classContains: "profile", in: window)
            + IGLocator.shared.findViews(classContains: "userinfo", in: window)

        for v in profiles {
            let n = NSStringFromClass(type(of: v)).lowercased()
            if n.contains("header") || n.contains("action") || n.contains("toolbar") || n.contains("button") {
                if v.bounds.height > 34 && v.bounds.height < 120 {
                    GlassMaterial.shared.apply(to: v, style: .soft, corner: 12)
                    if p.animations { GlassAnimations.shared.attachPress(to: v) }
                }
            }
        }

        let actions = IGLocator.shared.findViews(classContains: "follow", in: window)
            + IGLocator.shared.findViews(classContains: "message", in: window)
            + IGLocator.shared.findViews(classContains: "contact", in: window)

        for b in actions where b is UIControl || b is UIButton {
            if p.glossyMode {
                b.layer.cornerCurve = .continuous
                b.layer.cornerRadius = 12
            }
            if p.animations { GlassAnimations.shared.attachPress(to: b) }
        }
    }
}
