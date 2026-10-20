import UIKit

/// Direct Messages chrome — composer, bubbles area, call buttons with circle
@objc public final class GlassDMChrome: NSObject {
    @objc public static let shared = GlassDMChrome()

    @objc public func apply(in window: UIView) {
        let prefs = GlassPreferences.shared
        guard prefs.styleDMs else { return }

        // Composer / input bar
        let composers = IGLocator.shared.findViews(classContains: "composer", in: window)
            + IGLocator.shared.findViews(classContains: "input", in: window)
            + IGLocator.shared.findViews(classContains: "messagebar", in: window)
            + IGLocator.shared.findViews(classContains: "chatbar", in: window)

        for c in composers {
            if c.bounds.height > 36 && c.bounds.height < 90 {
                GlassMaterial.shared.apply(to: c, style: .soft, corner: 18)
                if prefs.animations { GlassAnimations.shared.attachPress(to: c) }
            }
        }

        // Call / video call buttons — give them a glass circle
        let callCandidates = IGLocator.shared.findViews(classContains: "call", in: window)
            + IGLocator.shared.findViews(classContains: "video", in: window)
            + IGLocator.shared.findViews(classContains: "phone", in: window)

        for btn in callCandidates {
            let name = NSStringFromClass(type(of: btn)).lowercased()
            // Prefer actual buttons / controls
            if btn is UIControl || name.contains("button") {
                // Only treat reasonably square controls as call buttons
                let s = min(btn.bounds.width, btn.bounds.height)
                if s > 28 && s < 64 {
                    GlassMaterial.shared.applyCircle(to: btn)
                    if prefs.animations { GlassAnimations.shared.attachPress(to: btn) }
                }
            }
        }

        // Thread header / nav area inside DMs
        let headers = IGLocator.shared.findViews(classContains: "threadheader", in: window)
            + IGLocator.shared.findViews(classContains: "dmheader", in: window)
            + IGLocator.shared.findViews(classContains: "inboxheader", in: window)

        for h in headers {
            if h.bounds.height > 40 && h.bounds.height < 100 {
                GlassMaterial.shared.apply(to: h, style: .standard, corner: 0)
            }
        }
    }
}
