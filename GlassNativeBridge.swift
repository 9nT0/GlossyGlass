import UIKit

/// High-level glass capability helpers on top of GlassPrivateBridge.
@objc public final class GlassNativeBridge: NSObject {

    @objc public static var hasUIGlassEffect: Bool {
        GlassPrivateBridge.hasUIGlassEffect
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
