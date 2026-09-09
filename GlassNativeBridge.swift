import UIKit

/// Uses real UIGlassEffect on iOS 26+ when the class exists at runtime.
@objc public class GlassNativeBridge: NSObject {

    @objc public static var isNativeGlassAvailable: Bool {
        NSClassFromString("UIGlassEffect") != nil
    }

    @objc public static func makeNativeGlassView(styleClear: Bool) -> UIVisualEffectView? {
        guard let glassClass = NSClassFromString("UIGlassEffect") as? NSObject.Type else {
            return nil
        }
        // UIGlassEffect inherits UIVisualEffect — allocate via ObjC runtime
        let effect: AnyObject?
        if styleClear, glassClass.responds(to: NSSelectorFromString("clearEffect")) {
            effect = glassClass.perform(NSSelectorFromString("clearEffect"))?.takeUnretainedValue()
        } else if glassClass.responds(to: NSSelectorFromString("effectWithStyle:")) {
            // Some betas use style enum — fall through to init
            effect = glassClass.init()
        } else {
            effect = glassClass.init()
        }
        guard let visual = effect as? UIVisualEffect else { return nil }
        let v = UIVisualEffectView(effect: visual)
        v.clipsToBounds = true
        return v
    }

    @objc public static func fallbackBlur(dark: Bool, lightweight: Bool) -> UIBlurEffect {
        if lightweight { return UIBlurEffect(style: .systemUltraThinMaterial) }
        if dark { return UIBlurEffect(style: .systemThinMaterialDark) }
        return UIBlurEffect(style: .systemThinMaterialLight)
    }
}
