import UIKit

/// Profile surfaces
@objc public final class GlassProfileChrome: NSObject {
    @objc public static let shared = GlassProfileChrome()

    @objc public func apply(in window: UIView) {
        let prefs = GlassPreferences.shared
        guard prefs.styleProfiles else { return }

        let profiles = IGLocator.shared.findViews(classContains: "profile", in: window)
            + IGLocator.shared.findViews(classContains: "userinfo", in: window)

        for v in profiles {
            let n = NSStringFromClass(type(of: v)).lowercased()
            if n.contains("header") || n.contains("action") || n.contains("toolbar") || n.contains("button") {
                if v.bounds.height > 36 && v.bounds.height < 110 {
                    GlassMaterial.shared.apply(to: v, style: .soft, corner: 14)
                    if prefs.animations { GlassAnimations.shared.attachPress(to: v) }
                }
            }
        }

        // Follow / Message / Contact buttons on profiles
        let actions = IGLocator.shared.findViews(classContains: "follow", in: window)
            + IGLocator.shared.findViews(classContains: "message", in: window)
            + IGLocator.shared.findViews(classContains: "contact", in: window)

        for b in actions {
            if b is UIControl || b is UIButton {
                if prefs.glossyMode {
                    b.layer.cornerCurve = .continuous
                    b.layer.cornerRadius = 12
                }
                if prefs.animations { GlassAnimations.shared.attachPress(to: b) }
            }
        }
    }
}
