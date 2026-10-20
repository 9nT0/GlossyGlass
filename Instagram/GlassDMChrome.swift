import UIKit

@objc public final class GlassDMChrome: NSObject {
    @objc public static let shared = GlassDMChrome()

    @objc public func apply(in window: UIView) {
        let p = GlassPreferences.shared
        guard p.styleDMs else { return }

        let composers = IGLocator.shared.findViews(classContains: "composer", in: window)
            + IGLocator.shared.findViews(classContains: "input", in: window)
            + IGLocator.shared.findViews(classContains: "messagebar", in: window)
            + IGLocator.shared.findViews(classContains: "chatbar", in: window)
            + IGLocator.shared.findViews(classContains: "textbox", in: window)

        for c in composers where c.bounds.height > 34 && c.bounds.height < 95 {
            GlassMaterial.shared.apply(to: c, style: .soft, corner: 18)
            if p.animations { GlassAnimations.shared.attachPress(to: c) }
        }

        let calls = IGLocator.shared.findViews(classContains: "call", in: window)
            + IGLocator.shared.findViews(classContains: "video", in: window)
            + IGLocator.shared.findViews(classContains: "phone", in: window)

        for btn in calls {
            let n = NSStringFromClass(type(of: btn)).lowercased()
            if btn is UIControl || n.contains("button") {
                let s = min(btn.bounds.width, btn.bounds.height)
                if s > 26 && s < 70 {
                    GlassMaterial.shared.applyCircle(to: btn)
                    if p.animations { GlassAnimations.shared.attachPress(to: btn) }
                }
            }
        }

        let headers = IGLocator.shared.findViews(classContains: "threadheader", in: window)
            + IGLocator.shared.findViews(classContains: "dmheader", in: window)
            + IGLocator.shared.findViews(classContains: "inboxheader", in: window)

        for h in headers where h.bounds.height > 38 && h.bounds.height < 110 {
            GlassMaterial.shared.apply(to: h, style: .standard, corner: 0)
        }
    }
}
