import UIKit

/// High-level glass capability helpers on top of GlassPrivateBridge.
@objc public final class GlassNativeBridge: NSObject {

    @objc public static var hasUIGlassEffect: Bool {
        GlassPrivateBridge.hasUIGlassEffect
    }

    /// Used by HealthChecker / Welcome
    @objc public static var isNativeGlassAvailable: Bool {
        hasUIGlassEffect
    }

    @objc public static func makePreferredGlass(clear: Bool, intensity: CGFloat) -> UIVisualEffect {
        if hasUIGlassEffect, let g = GlassPrivateBridge.makeGlassEffect(clear: clear || intensity < 0.42) {
            return g
        }
        return GlassMaterialEngine.shared.blurEffect(
            style: clear ? "clear" : "frosted",
            dark: true,
            intensity: intensity
        )
    }

    /// Optional native glass effect view for GlassView path
    @objc public static func makeNativeGlassView(styleClear: Bool) -> UIVisualEffectView? {
        guard hasUIGlassEffect,
              let effect = GlassPrivateBridge.makeGlassEffect(clear: styleClear) else {
            return nil
        }
        let v = UIVisualEffectView(effect: effect)
        v.isUserInteractionEnabled = false
        v.clipsToBounds = true
        return v
    }

    @objc public static func fallbackBlur(dark: Bool, lightweight: Bool) -> UIVisualEffect {
        if lightweight {
            return UIBlurEffect(style: dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
        }
        return GlassPrivateBridge.systemChromeMaterial(dark: dark, ultraThin: false)
    }

    @objc public static func applyCapsuleShape(to view: UIView, height: CGFloat) {
        let r = height * 0.5
        view.layer.cornerRadius = r
        if #available(iOS 13.0, *) {
            view.layer.cornerCurve = .continuous
        }
        view.clipsToBounds = true
        GlassPrivateBridge.setContinuousCorners(view, radius: r)
    }
}
