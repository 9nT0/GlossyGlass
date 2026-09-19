import UIKit

/// Shared liquid-glass capsules for dock, nav bubbles, selected lens.
/// Prefers UIGlassEffect (iOS 26) when private bridge reports it.
@objc public final class GlassBubbleKit: NSObject {

    public static let dockTag: Int         = 0x4747_444B // GGDK
    public static let selectedTag: Int     = 0x4747_5345 // GGSE
    public static let navBubbleTag: Int    = 0x4747_4E42 // GGNB
    public static let plateTag: Int        = 0x4747_4D41 // GGMA
    public static let reelsChromeTag: Int  = 0x4747_5243 // GGRC
    public static let dmChromeTag: Int     = 0x4747_444D // GGDM
    public static let presentationTag: Int = 0x4747_5052 // GGPR

    // MARK: - Blur / glass effect

    @objc public static func makeBlur(style: String, intensity: CGFloat) -> UIVisualEffect {
        // Prefer real UIGlassEffect when available (iOS 26+)
        if GlassPrivateBridge.hasUIGlassEffect {
            let clear = style.lowercased() == "clear" || intensity < 0.45
            if let g = GlassPrivateBridge.makeGlassEffect(clear: clear) {
                return g
            }
        }
        return GlassMaterialEngine.shared.blurEffect(style: style, dark: true, intensity: intensity)
    }

    // MARK: - Install bubble (create-or-update by tag)

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
        } else {
            // Still update if not mid-animation keys for bounds
            bubble.frame = frame
        }

        // iOS 26 continuous capsule
        let r = min(frame.height, frame.width) * 0.48
        bubble.layer.cornerRadius = max(12, r)
        if #available(iOS 13.0, *) { bubble.layer.cornerCurve = .continuous }
        bubble.alpha = max(0.90, min(1, opacity))
        bubble.isHidden = false

        applyInnerLayers(to: bubble, style: style, intensity: intensity, selected: tag == selectedTag)
        return bubble
    }

    /// Soft selected-tab lens — morphs like a water droplet across the dock
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

        lens.layer.cornerRadius = min(frame.height, frame.width) * 0.45
        if #available(iOS 13.0, *) { lens.layer.cornerCurve = .continuous }

        // Brighter glass pill over selected item
        lens.backgroundColor = UIColor.white.withAlphaComponent(0.22 * max(0.55, intensity))
        lens.layer.borderWidth = 0.6
        lens.layer.borderColor = UIColor.white.withAlphaComponent(0.40 * intensity).cgColor
        lens.layer.shadowColor = UIColor.black.cgColor
        lens.layer.shadowOpacity = Float(0.20 * intensity)
        lens.layer.shadowRadius = 8
        lens.layer.shadowOffset = CGSize(width: 0, height: 2)
        lens.alpha = max(0.65, intensity)
        lens.isHidden = false
        return lens
    }

    // MARK: - Inner specular / tint (liquid look)

    private static func applyInnerLayers(
        to bubble: UIVisualEffectView,
        style: String,
        intensity: CGFloat,
        selected: Bool
    ) {
        let cv = bubble.contentView
        let tintTag = bubble.tag &+ 1
        let rimTag  = bubble.tag &+ 2
        let glowTag = bubble.tag &+ 3

        // Soft frost tint
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
        case "clear": frost = 0.06
        case "tinted": frost = 0.20
        case "liquid", "heavy": frost = 0.16
        default: frost = 0.12
        }
        tint.backgroundColor = UIColor.white.withAlphaComponent(frost * max(0.5, intensity) * (selected ? 1.3 : 1))

        // Specular top rim (glass highlight)
        let rim: UIView
        if let r = cv.viewWithTag(rimTag) { rim = r }
        else {
            rim = UIView()
            rim.tag = rimTag
            rim.isUserInteractionEnabled = false
            cv.addSubview(rim)
        }
        rim.frame = CGRect(x: 8, y: 0.5, width: max(0, bubble.bounds.width - 16), height: 0.7)
        rim.autoresizingMask = [.flexibleWidth]
        rim.backgroundColor = UIColor.white.withAlphaComponent(0.42 * intensity)
        rim.layer.cornerRadius = 0.35

        if selected {
            let glow: UIView
            if let g = cv.viewWithTag(glowTag) { glow = g }
            else {
                glow = UIView()
                glow.tag = glowTag
                glow.isUserInteractionEnabled = false
                cv.insertSubview(glow, at: 1)
            }
            glow.frame = cv.bounds.insetBy(dx: 4, dy: 4)
            glow.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            glow.backgroundColor = UIColor.white.withAlphaComponent(0.08 * intensity)
            glow.layer.cornerRadius = min(glow.bounds.height, glow.bounds.width) * 0.4
        }
    }
}
