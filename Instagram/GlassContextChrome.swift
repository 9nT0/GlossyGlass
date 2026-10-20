import UIKit

/// Long-press menus, action sheets, context menus
@objc public final class GlassContextChrome: NSObject {
    @objc public static let shared = GlassContextChrome()

    @objc public func apply(in window: UIView) {
        let p = GlassPreferences.shared
        guard p.styleContext else { return }

        // System action sheets / alert controllers
        let sheets = IGLocator.shared.findViews(classContains: "actionsheet", in: window)
            + IGLocator.shared.findViews(classContains: "alert", in: window)
            + IGLocator.shared.findViews(classContains: "contextmenu", in: window)
            + IGLocator.shared.findViews(classContains: "menu", in: window)
            + IGLocator.shared.findViews(classContains: "popover", in: window)

        for v in sheets {
            let h = v.bounds.height
            if h > 40 && h < 500 {
                GlassMaterial.shared.apply(to: v, style: p.glossyMode ? .strong : .soft, corner: 16)
                if p.animations {
                    for s in v.subviews where s is UIControl || s is UIButton {
                        GlassAnimations.shared.attachPress(to: s)
                    }
                }
            }
        }
    }
}
