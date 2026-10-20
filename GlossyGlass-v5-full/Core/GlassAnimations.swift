import UIKit

/// Spring scale hover / press animations (iOS 26 feel)
@objc public final class GlassAnimations: NSObject {
    @objc public static let shared = GlassAnimations()

    private var attached = Set<ObjectIdentifier>()

    /// Attach press animation to a view (scale down on touch)
    @objc public func attachPress(to view: UIView) {
        let id = ObjectIdentifier(view)
        guard !attached.contains(id) else { return }
        attached.insert(id)

        let press = UILongPressGestureRecognizer(target: self, action: #selector(handlePress(_:)))
        press.minimumPressDuration = 0.01
        press.cancelsTouchesInView = false
        press.delegate = PressDelegate.shared
        view.addGestureRecognizer(press)
        view.isUserInteractionEnabled = true
    }

    @objc private func handlePress(_ g: UILongPressGestureRecognizer) {
        guard GlassPreferences.shared.animations, let v = g.view else { return }

        switch g.state {
        case .began:
            UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4, options: [.allowUserInteraction]) {
                v.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.3, options: [.allowUserInteraction]) {
                v.transform = .identity
            }
        default:
            break
        }
    }

    /// Soft hover-like pulse (used on focus)
    @objc public func pulse(_ view: UIView) {
        guard GlassPreferences.shared.animations else { return }
        UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
            view.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
        } completion: { _ in
            UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3, options: [.allowUserInteraction]) {
                view.transform = .identity
            }
        }
    }
}

private final class PressDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = PressDelegate()
    func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}
