import UIKit
import ObjectiveC

@objc public final class GlassAnimations: NSObject {
    @objc public static let shared = GlassAnimations()
    private static var pressKey: UInt8 = 0

    @objc public func attachPress(to view: UIView) {
        if objc_getAssociatedObject(view, &Self.pressKey) as? Bool == true { return }
        objc_setAssociatedObject(view, &Self.pressKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        let g = UILongPressGestureRecognizer(target: self, action: #selector(press(_:)))
        g.minimumPressDuration = 0.01
        g.cancelsTouchesInView = false
        g.delegate = PressGate.shared
        view.addGestureRecognizer(g)
        view.isUserInteractionEnabled = true
    }

    @objc private func press(_ g: UILongPressGestureRecognizer) {
        guard GlassPreferences.shared.animations, let v = g.view else { return }
        switch g.state {
        case .began:
            UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
                v.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.62, initialSpringVelocity: 0.35, options: [.allowUserInteraction]) {
                v.transform = .identity
            }
        default: break
        }
    }
}

private final class PressGate: NSObject, UIGestureRecognizerDelegate {
    static let shared = PressGate()
    func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}
