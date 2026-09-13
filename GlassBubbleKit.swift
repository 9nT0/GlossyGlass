import UIKit

/// Shared iOS-26 liquid glass bubble component.
/// States: idle → pressed → selected → expanded → morphing → dismissed
/// Tags are stable so overlays are create-or-update, never stacked.
@objc public final class GlassBubbleKit: NSObject {

    // MARK: - Stable tags (never collide with UIKit)

    public static let dockTag: Int       = 0x4747_444B // GGDK
    public static let selectedTag: Int   = 0x4747_5345 // GGSE
    public static let navBubbleTag: Int  = 0x4747_4E42 // GGNB
    public static let plateTag: Int      = 0x4747_4D41 // GGMA (legacy; prefer dockTag)
    public static let reelsChromeTag: Int = 0x4747_5243 // GGRC
    public static let dmChromeTag: Int   = 0x4747_444D // GGDM
    public static let presentationTag: Int = 0x4747_5052 // GGPR

    public enum BubbleState: Int {
        case idle = 0
        case pressed
        case selected
        case expanded
        case morphing
        case dismissed
    }

    // MARK: - Blur helper

    @objc public static func makeBlur(style: String, intensity: CGFloat) -> UIBlurEffect {
        GlassMaterialEngine.shared.blurEffect(style: style, dark: true, intensity: intensity)
    }

    // MARK: - Install / update bubble (create-or-update by tag)

    /// Continuous capsule with blur + rim + tint. Never nests effect views.
    @discardableResult
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

        if bubble.layer.animationKeys()?.isEmpty ?? true {
            bubble.frame = frame
        }

        let r = min(frame.height, frame.width) * 0.48
        bubble.layer.cornerRadius = max(10, r)
        if #available(iOS 13.0, *) { bubble.layer.cornerCurve = .continuous }
        bubble.alpha = max(0.88, min(1, opacity))
        bubble.isHidden = false

        applyInnerLayers(to: bubble, style: style, intensity: intensity, selected: tag == selectedTag)
        return bubble
    }

    /// Soft non-blur lens for selected tab indicator (cheaper, morph-friendly).
    @discardableResult
    @objc public static func installSelectedLens(
        into host: UIView,
        frame: CGRect,
        intensity: CGFloat
    ) -> UIView {
        let tag = selectedTag
        let lens: UIView
        if let existing = host.viewWithTag(tag) {
            lens = existing
        } else {
            lens = UIView(frame: frame)
            lens.tag = tag
            lens.isUserInteractionEnabled = false
            lens.clipsToBounds = true
            host.insertSubview(lens, at: 1)
        }

        lens.layer.cornerRadius = min(frame.height, frame.width) * 0.42
        if #available(iOS 13.0, *) { lens.layer.cornerCurve = .continuous }
        lens.backgroundColor = UIColor.white.withAlphaComponent(0.16 * max(0.5, intensity))
        lens.layer.borderWidth = 0.5
        lens.layer.borderColor = UIColor.white.withAlphaComponent(0.32 * intensity).cgColor
        lens.layer.shadowColor = UIColor.black.cgColor
        lens.layer.shadowOpacity = Float(0.18 * intensity)
        lens.layer.shadowRadius = 6
        lens.layer.shadowOffset = CGSize(width: 0, height: 2)
        lens.alpha = max(0.55, intensity)
        lens.isHidden = false
        return lens
    }

    private static func applyInnerLayers(to bubble: UIVisualEffectView, style: String, intensity: CGFloat, selected: Bool) {
        let cv = bubble.contentView
        let tintTag = bubble.tag &+ 1
        let rimTag  = bubble.tag &+ 2
        let glowTag = bubble.tag &+ 3

        let tint: UIView
        if let t = cv.viewWithTag(tintTag) { tint = t }
        else {
            tint = UIView()
            tint.tag = tintTag
            tint.isUserInteractionEnabled = false
            cv.insertSubview(tint, at: 0)
        }
        tint.frame = cv.bounds
        tint.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let frost: CGFloat
        switch style.lowercased() {
        case "clear": frost = 0.07
        case "tinted": frost = 0.22
        case "liquid", "heavy": frost = 0.18
        default: frost = 0.14
        }
        tint.backgroundColor = UIColor.white.withAlphaComponent(frost * max(0.5, intensity) * (selected ? 1.25 : 1))

        let rim: UIView
        if let r = cv.viewWithTag(rimTag) { rim = r }
        else {
            rim = UIView()
            rim.tag = rimTag
            rim.isUserInteractionEnabled = false
            cv.addSubview(rim)
        }
        rim.frame = CGRect(x: 5, y: 0.4, width: max(0, bubble.bounds.width - 10), height: 0.6)
        rim.autoresizingMask = [.flexibleWidth]
        rim.backgroundColor = UIColor.white.withAlphaComponent(0.38 * intensity)

        if selected {
            let glow: UIView
            if let g = cv.viewWithTag(glowTag) { glow = g }
            else {
                glow = UIView()
                glow.tag = glowTag
                glow.isUserInteractionEnabled = false
                cv.insertSubview(glow, at: 1)
            }
            glow.frame = cv.bounds.insetBy(dx: 2, dy: 2)
            glow.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            glow.backgroundColor = UIColor.white.withAlphaComponent(0.06 * intensity)
            glow.layer.cornerRadius = bubble.layer.cornerRadius - 2
        }
    }

    // MARK: - Motion

    @objc public static func springMove(_ view: UIView, to frame: CGRect) {
        let prefs = GlassPreferences.shared
        let damping = max(0.55, min(0.92, prefs.springDamping))
        let response = max(0.18, min(0.55, prefs.springResponse))
        UIView.animate(
            withDuration: Double(response) * 1.55,
            delay: 0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: 0.6,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseInOut]
        ) {
            view.frame = frame
            view.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
        } completion: { _ in
            UIView.animate(withDuration: 0.16, delay: 0, options: [.beginFromCurrentState]) {
                view.transform = .identity
            }
        }
    }

    @objc public static func press(_ view: UIView) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            view.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            view.alpha = max(0.7, view.alpha * 0.9)
        }
    }

    @objc public static func releasePress(_ view: UIView) {
        UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4, options: [.beginFromCurrentState]) {
            view.transform = .identity
            view.alpha = 1
        }
    }

    @objc public static func dismiss(_ view: UIView, animated: Bool = true) {
        guard animated else {
            view.removeFromSuperview()
            return
        }
        UIView.animate(withDuration: 0.2, animations: {
            view.alpha = 0
            view.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }, completion: { _ in
            view.removeFromSuperview()
        })
    }

    /// Find existing tagged overlay or return nil (never create duplicates).
    @objc public static func existing(tag: Int, in host: UIView) -> UIView? {
        host.viewWithTag(tag)
    }
}
