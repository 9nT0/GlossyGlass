import UIKit

@objc public class GlassAnimations: NSObject {

    @objc public static func pressIn(_ view: UIView, scale: CGFloat = 0.965) {
        let prefs = GlassPreferences.shared
        UIView.animate(
            withDuration: prefs.springResponse,
            delay: 0,
            usingSpringWithDamping: prefs.springDamping,
            initialSpringVelocity: 0.55,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    @objc public static func pressOut(_ view: UIView) {
        let prefs = GlassPreferences.shared
        UIView.animate(
            withDuration: prefs.springResponse + 0.06,
            delay: 0,
            usingSpringWithDamping: prefs.springDamping + 0.04,
            initialSpringVelocity: 0.4,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            view.transform = .identity
        }
    }

    @objc public static func longPressLift(_ view: UIView, intensity: CGFloat = 1.0) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled else { return }
        let lift: CGFloat = 1.03 * intensity
        let shadowOpacity: Float = prefs.lightweightMode ? 0.12 : 0.18

        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.5,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            view.transform = CGAffineTransform(scaleX: lift, y: lift)
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = shadowOpacity
            view.layer.shadowRadius = 18
            view.layer.shadowOffset = CGSize(width: 0, height: 8)
        }
    }

    @objc public static func longPressRelease(_ view: UIView) {
        UIView.animate(
            withDuration: 0.36,
            delay: 0,
            usingSpringWithDamping: 0.78,
            initialSpringVelocity: 0.4,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            view.transform = .identity
            view.layer.shadowOpacity = 0
            view.layer.shadowRadius = 0
        }
    }
}
