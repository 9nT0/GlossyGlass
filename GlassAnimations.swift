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

    static func longPressLift(_ view: UIView) {
        let reduce = UIAccessibility.isReduceMotionEnabled
        if reduce {
            UIView.animate(withDuration: 0.12) {
                view.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
                view.alpha = 0.96
            }
            return
        }
        // iOS 26-style soft lift: scale + shadow bloom
        view.layer.masksToBounds = false
        let anim = CASpringAnimation(keyPath: "transform.scale")
        anim.fromValue = 1.0
        anim.toValue = 1.045
        anim.mass = 0.8
        anim.stiffness = 180
        anim.damping = 16
        anim.duration = anim.settlingDuration
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        view.layer.add(anim, forKey: "gg.lift")

        let shadow = CABasicAnimation(keyPath: "shadowOpacity")
        shadow.fromValue = 0
        shadow.toValue = 0.28
        shadow.duration = 0.22
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 16
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.add(shadow, forKey: "gg.shadow")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.4) {
                view.transform = .identity
            }
            view.layer.shadowOpacity = 0
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
