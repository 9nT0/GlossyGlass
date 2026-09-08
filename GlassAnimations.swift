import UIKit

/// Smoother springs for v3.6 — slightly longer, higher damping, less bounce
@objc public class GlassAnimations: NSObject {

    private static var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private static var response: CGFloat {
        max(0.18, min(0.55, GlassPreferences.shared.springResponse))
    }

    private static var damping: CGFloat {
        max(0.55, min(0.95, GlassPreferences.shared.springDamping + 0.06))
    }

    @objc public static func pressIn(_ view: UIView, scale: CGFloat = 0.978) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled else { return }
        if reduceMotion {
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
            return
        }
        UIView.animate(
            withDuration: TimeInterval(response),
            delay: 0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: 0.35,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]
        ) {
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    @objc public static func pressOut(_ view: UIView) {
        if reduceMotion {
            view.transform = .identity
            return
        }
        UIView.animate(
            withDuration: TimeInterval(response + 0.08),
            delay: 0,
            usingSpringWithDamping: min(0.98, damping + 0.05),
            initialSpringVelocity: 0.25,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]
        ) {
            view.transform = .identity
        }
    }

    @objc public static func longPressLift(_ view: UIView, intensity: CGFloat = 1.0) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled else { return }
        let lift: CGFloat = reduceMotion ? 1.0 : (1.025 * intensity)
        let shadowOpacity: Float = prefs.lightweightMode ? 0.10 : 0.16

        if reduceMotion {
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = shadowOpacity * 0.5
            view.layer.shadowRadius = 10
            view.layer.shadowOffset = CGSize(width: 0, height: 4)
            return
        }

        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.3,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]
        ) {
            view.transform = CGAffineTransform(scaleX: lift, y: lift)
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = shadowOpacity
            view.layer.shadowRadius = 16
            view.layer.shadowOffset = CGSize(width: 0, height: 6)
        }
    }

    @objc public static func longPressRelease(_ view: UIView) {
        if reduceMotion {
            view.transform = .identity
            view.layer.shadowOpacity = 0
            view.layer.shadowRadius = 0
            return
        }
        UIView.animate(
            withDuration: 0.40,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0.22,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]
        ) {
            view.transform = .identity
            view.layer.shadowOpacity = 0
            view.layer.shadowRadius = 0
        }
    }

    @objc public static func fadeInGlass(_ view: UIView, duration: TimeInterval = 0.40) {
        if reduceMotion {
            view.alpha = 1
            return
        }
        view.alpha = 0
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.90,
            initialSpringVelocity: 0.2,
            options: [.allowUserInteraction, .curveEaseOut]
        ) {
            view.alpha = 1
        }
    }
}
