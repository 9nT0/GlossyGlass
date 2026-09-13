import UIKit

/// Shared iOS-26 style glass bubble (nav chips, selected tab indicator, control pills).
@objc public final class GlassBubbleKit: NSObject {

    public static let dockTag: Int = 0x4747_444B       // GGDK
    public static let selectedTag: Int = 0x4747_5345  // GGSE
    public static let navBubbleTag: Int = 0x4747_4E42 // GGNB
    public static let plateTag: Int = 0x4747_4D41     // GGMA

    @objc public static func makeBlur(style: String, intensity: CGFloat) -> UIBlurEffect {
        GlassMaterialEngine.shared.blurEffect(style: style, dark: true, intensity: intensity)
    }

    /// Continuous capsule with blur + rim + optional tint. Never nests effect views.
    @objc public static func installBubble(
        into host: UIView,
        tag: Int,
        frame: CGRect,
        style: String,
        intensity: CGFloat,
        opacity: CGFloat
    ) -> UIVisualEffectView {
        let effect = makeBlur(style: style, intensity: intensity)
        let bubble: UIVisualEffectView
        if let existing = host.viewWithTag(tag) as? UIVisualEffectView {
            bubble = existing
            bubble.effect = effect
        } else {
            bubble = UIVisualEffectView(effect: effect)
            bubble.tag = tag
            bubble.isUserInteractionEnabled = false
            bubble.clipsToBounds = true
            host.insertSubview(bubble, at: 0)
        }
        bubble.frame = frame
        let r = min(frame.height, frame.width) * 0.48
        bubble.layer.cornerRadius = r
        if #available(iOS 13.0, *) { bubble.layer.cornerCurve = .continuous }
        bubble.alpha = max(0.88, min(1, opacity))
        bubble.isHidden = false

        // Tint on contentView only
        let tintTag = tag &+ 1
        let tint: UIView
        if let t = bubble.contentView.viewWithTag(tintTag) {
            tint = t
        } else {
            tint = UIView()
            tint.tag = tintTag
            tint.isUserInteractionEnabled = false
            bubble.contentView.insertSubview(tint, at: 0)
        }
        tint.frame = bubble.contentView.bounds
        tint.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let frost: CGFloat = style.lowercased() == "clear" ? 0.08 : 0.16
        tint.backgroundColor = UIColor.white.withAlphaComponent(frost * max(0.5, intensity))

        // Edge highlight
        let rimTag = tag &+ 2
        let rim: UIView
        if let r = bubble.contentView.viewWithTag(rimTag) {
            rim = r
        } else {
            rim = UIView()
            rim.tag = rimTag
            rim.isUserInteractionEnabled = false
            bubble.contentView.addSubview(rim)
        }
        rim.frame = CGRect(x: 6, y: 0.5, width: max(0, frame.width - 12), height: 0.6)
        rim.autoresizingMask = [.flexibleWidth]
        rim.backgroundColor = UIColor.white.withAlphaComponent(0.35 * intensity)

        return bubble
    }

    @objc public static func springMove(_ view: UIView, to frame: CGRect) {
        UIView.animate(
            withDuration: 0.42,
            delay: 0,
            usingSpringWithDamping: 0.78,
            initialSpringVelocity: 0.55,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            view.frame = frame
            view.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
        } completion: { _ in
            UIView.animate(withDuration: 0.18) {
                view.transform = .identity
            }
        }
    }
}
