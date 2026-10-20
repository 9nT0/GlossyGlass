import UIKit

@objc public final class GlassProfileChrome: NSObject {
    @objc public static let shared = GlassProfileChrome()

    @objc public func apply(in window: UIView) {
        let p = GlassPreferences.shared
        guard p.styleProfiles else { return }

        let profiles = IGLocator.shared.findViews(classContains: "profile", in: window)
            + IGLocator.shared.findViews(classContains: "userinfo", in: window)

        for v in profiles {
            guard !IGLocator.shared.isContent(v) else { continue }
            let n = NSStringFromClass(type(of: v)).lowercased()
            if n.contains("header") || n.contains("action") || n.contains("toolbar") || n.contains("button") || n.contains("stats") {
                if v.bounds.height > 32 && v.bounds.height < 140 {
                    GlassMaterial.shared.apply(to: v, style: .soft, corner: 14)
                    if p.animations { GlassAnimations.shared.attachPress(to: v) }
                }
            }
        }
        let actions = IGLocator.shared.findViews(classContains: "follow", in: window)
            + IGLocator.shared.findViews(classContains: "message", in: window)
        for b in actions where b is UIControl || b is UIButton {
            guard !IGLocator.shared.isContent(b) else { continue }
            if p.glossyMode {
                b.layer.cornerCurve = .continuous
                b.layer.cornerRadius = 12
            }
            if p.animations { GlassAnimations.shared.attachPress(to: b) }
        }
    }
}
