import UIKit

/// Profiles — including when opened from DMs / deep links
@objc public final class GlassProfileChrome: NSObject {
    @objc public static let shared = GlassProfileChrome()

    @objc public func apply(in window: UIView) {
        let p = GlassPreferences.shared
        guard p.styleProfiles else { return }

        // Broad discovery: profile, user, header, stats, action bars
        let keys = ["profile", "userinfo", "userdetail", "profileheader", "profilestats",
                    "actionbar", "profileaction", "followbutton", "messagebutton"]
        var views: [UIView] = []
        for k in keys { views += IGLocator.shared.findViews(classContains: k, in: window) }

        for v in views {
            guard !IGLocator.shared.isContent(v) else { continue }
            let n = NSStringFromClass(type(of: v)).lowercased()
            let h = v.bounds.height
            // Header / stats cards
            if (n.contains("header") || n.contains("stats") || n.contains("info")) && h > 40 && h < 160 {
                GlassMaterial.shared.apply(to: v, style: .soft, corner: 16)
                continue
            }
            // Action rows / buttons
            if (n.contains("action") || n.contains("button") || n.contains("toolbar") || n.contains("follow") || n.contains("message")) && h > 28 && h < 70 {
                GlassMaterial.shared.apply(to: v, style: .soft, corner: 12)
                if p.animations { GlassAnimations.shared.attachPress(to: v) }
            }
        }

        // Follow / Message pills on any profile
        for b in IGLocator.shared.findViews(classContains: "follow", in: window)
            + IGLocator.shared.findViews(classContains: "message", in: window) {
            guard b is UIControl || b is UIButton else { continue }
            guard !IGLocator.shared.isContent(b) else { continue }
            if b.bounds.height > 28 && b.bounds.height < 56 {
                b.layer.cornerCurve = .continuous
                b.layer.cornerRadius = b.bounds.height * 0.45
                if p.animations { GlassAnimations.shared.attachPress(to: b) }
            }
        }
    }
}
