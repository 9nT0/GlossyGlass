import UIKit

/// Advanced liquid-glass capsules — UIGlassEffect on 26+, layered fallback below.
@objc public final class GlassBubbleKit: NSObject {

    public static let dockTag: Int         = 0x4747_444B // GGDK
    public static let selectedTag: Int     = 0x4747_5345 // GGSE
    public static let navBubbleTag: Int    = 0x4747_4E42 // GGNB
    public static let plateTag: Int        = 0x4747_4D41 // GGMA
    public static let reelsChromeTag: Int  = 0x4747_5243 // GGRC
    public static let dmChromeTag: Int     = 0x4747_444D // GGDM
    public static let presentationTag: Int = 0x4747_5052 // GGPR

    // MARK: - Effect

    @objc public static func makeBlur(style: String, intensity: CGFloat) -> UIVisualEffect {
        let clear = style.lowercased() == "clear" || intensity < 0.45
        return GlassNativeBridge.makePreferredGlass(clear: clear, intensity: intensity)
    }

    // MARK: - Bubble (create-or-update)

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
            if bubble.effect !== effect { bubble.effect = effect }
        } else {
            bubble = UIVisualEffectView(effect: effect)
            bubble.tag = tag
            bubble.isUserInteractionEnabled = false
            bubble.clipsToBounds = true
            host.insertSubview(bubble, at: 0)
        }

        let moved = abs(bubble.frame.midX - frame.midX) > 0.5
            || abs(bubble.frame.midY - frame.midY) > 0.5
            || abs(bubble.frame.width - frame.width) > 0.5
        if moved {
            bubble.frame = frame
        }

        GlassNativeBridge.applyCapsuleShape(to: bubble, height: frame.height)
        decorate(bubble, intensity: intensity, opacity: opacity, style: style)
        bubble.alpha = max(0.75, min(1.0, opacity))
        bubble.isHidden = false
        return bubble
    }

    // MARK: - Selected lens (morphing water drop)

    @discardableResult
    @objc public static func installSelectedLens(
        into host: UIView,
        frame: CGRect,
        intensity: CGFloat
    ) -> UIView {
        let tag = selectedTag
        let effect = makeBlur(style: "clear", intensity: max(0.7, intensity))
        let lens: UIVisualEffectView
        if let existing = host.viewWithTag(tag) as? UIVisualEffectView {
            lens = existing
            lens.effect = effect
        } else {
            lens = UIVisualEffectView(effect: effect)
            lens.tag = tag
            lens.isUserInteractionEnabled = false
            lens.clipsToBounds = true
            host.insertSubview(lens, at: 1)
        }

        GlassNativeBridge.applyCapsuleShape(to: lens, height: frame.height)
        decorate(lens, intensity: intensity, opacity: 0.96, style: "clear")

        // Soft specular rim
        lens.layer.borderWidth = 0.5
        lens.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        lens.layer.shadowColor = UIColor.black.cgColor
        lens.layer.shadowOpacity = 0.18
        lens.layer.shadowRadius = 8
        lens.layer.shadowOffset = CGSize(width: 0, height: 3)
        lens.layer.masksToBounds = false

        return lens
    }

    // MARK: - Decoration

    private static func decorate(
        _ bubble: UIVisualEffectView,
        intensity: CGFloat,
        opacity: CGFloat,
        style: String
    ) {
        let cv = bubble.contentView
        // Tint plate
        let tintTag = 0x4747_544E // GGTN
        var tint = cv.viewWithTag(tintTag)
        if tint == nil {
            let v = UIView()
            v.tag = tintTag
            v.isUserInteractionEnabled = false
            cv.insertSubview(v, at: 0)
            tint = v
        }
        tint?.frame = cv.bounds
        tint?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let clear = style.lowercased() == "clear"
        let base: CGFloat = clear ? 0.08 : 0.14
        tint?.backgroundColor = UIColor.white.withAlphaComponent(base * max(0.5, intensity))

        // Specular top edge
        let glowTag = 0x4747_474C // GGGL
        var glow = cv.viewWithTag(glowTag)
        if glow == nil {
            let g = UIView()
            g.tag = glowTag
            g.isUserInteractionEnabled = false
            cv.insertSubview(g, at: 1)
            glow = g
        }
        let h = max(6, bubble.bounds.height * 0.22)
        glow?.frame = CGRect(x: 4, y: 1, width: max(0, bubble.bounds.width - 8), height: h)
        glow?.autoresizingMask = [.flexibleWidth]
        glow?.backgroundColor = UIColor.white.withAlphaComponent(0.12 * intensity)
        glow?.layer.cornerRadius = h * 0.5
        if #available(iOS 13.0, *) { glow?.layer.cornerCurve = .continuous }

        // Outer soft shadow on host layer
        bubble.layer.shadowColor = UIColor.black.cgColor
        bubble.layer.shadowOpacity = Float(0.22 * max(0.4, intensity))
        bubble.layer.shadowRadius = 12
        bubble.layer.shadowOffset = CGSize(width: 0, height: 4)
        bubble.layer.masksToBounds = false
        bubble.layer.borderWidth = 0.35
        bubble.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
    }

    @objc public static func removeBubble(tag: Int, from host: UIView) {
        host.viewWithTag(tag)?.removeFromSuperview()
    }
}
