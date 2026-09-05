import UIKit

/// Smoother spring animations and iOS 26-style press / long-press feedback
@objc public class GlassAnimations: NSObject {

    // MARK: - Standard press (used by GlassView / GlassButton)

    @objc public static func pressIn(_ view: UIView, scale: CGFloat = 0.965) {
        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            usingSpringWithDamping: 0.68,
            initialSpringVelocity: 0.6,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    @objc public static func pressOut(_ view: UIView) {
        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.72,
            initialSpringVelocity: 0.45,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            view.transform = .identity
        }
    }

    // MARK: - iOS 26 style long-press / message lift

    /// Applies a soft “lifted glass” look when long-pressing a message or cell
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

    // MARK: - Fade appearance

    @objc public static func fadeInGlass(_ view: UIView, duration: TimeInterval = 0.35) {
        view.alpha = 0
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.3,
            options: [.allowUserInteraction]
        ) {
            view.alpha = 1
        }
    }
}
