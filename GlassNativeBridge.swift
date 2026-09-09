import UIKit

/// Uses real UIGlassEffect on iOS 26+ when the class exists; otherwise fallback materials.
@objc public class GlassNativeBridge: NSObject {

    @objc public static var isNativeGlassAvailable: Bool {
        if #available(iOS 26.0, *) {
            return NSClassFromString("UIGlassEffect") != nil
        }
        return false
    }

    /// Best-effort native glass visual effect view for iOS 26+.
    @objc public static func makeNativeGlassView(styleClear: Bool) -> UIVisualEffectView? {
        guard #available(iOS 26.0, *) else { return nil }
        guard let glassClass = NSClassFromString("UIGlassEffect") as? NSObject.Type else { return nil }

        // UIGlassEffect() via runtime
        let effect: UIVisualEffect?
        if styleClear {
            // Prefer clear style selector if present
            if glassClass.responds(to: Selector(("clearEffect"))) {
                effect = glassClass.perform(Selector(("clearEffect")))?.takeUnretainedValue() as? UIVisualEffect
            } else {
                effect = (glassClass as? UIVisualEffect.Type).map { $0.init() } 
                    ?? (NSClassFromString("UIBlurEffect") as? UIBlurEffect.Type).map { $0.init(style: .systemUltraThinMaterial) }
            }
        } else {
            effect = (glassClass as? UIVisualEffect.Type).map { $0.init() }
                ?? UIBlurEffect(style: .systemThinMaterial)
        }
        guard let effect else { return nil }
        let v = UIVisualEffectView(effect: effect)
        v.clipsToBounds = true
        return v
    }

    @objc public static func fallbackBlur(dark: Bool, lightweight: Bool) -> UIBlurEffect {
        if lightweight { return UIBlurEffect(style: .systemUltraThinMaterial) }
        if dark { return UIBlurEffect(style: .systemThinMaterialDark) }
        return UIBlurEffect(style: .systemThinMaterialLight)
    }
}
