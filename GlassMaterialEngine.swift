import UIKit

/// Layered glossy glass renderer. Chrome uses small bubbles only — no full-width slabs.
/// BACKDROP → blur → luminance → specular rim → edge → bloom
@objc public final class GlassMaterialEngine: NSObject {

    @objc public static let shared = GlassMaterialEngine()

    private let plateTag = 0x4747_4D41
    private let tintTag  = 0x4747_544E
    private let rimTag   = 0x4747_524D
    private let edgeTag  = 0x4747_4544
    private let bloomTag = 0x4747_424C

    @objc public func blurEffect(style: String, dark: Bool, intensity: CGFloat) -> UIBlurEffect {
        let s = style.lowercased()
        if s == "clear" || intensity < 0.35 {
            return UIBlurEffect(style: dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
        }
        if s == "tinted" {
            return UIBlurEffect(style: dark ? .systemMaterialDark : .systemMaterialLight)
        }
        if s == "liquid" || s == "heavy" {
            return UIBlurEffect(style: dark ? .systemThinMaterialDark : .systemThinMaterialLight)
        }
        return UIBlurEffect(style: dark ? .systemChromeMaterialDark : .systemChromeMaterialLight)
    }

    /// Install material. `compact` always preferred for chrome (curved inset only).
    /// Full-strip path is intentionally disabled for nav/tab — use GlassBubbleKit instead.
    @objc public func install(into host: UIView, style: String, intensity: CGFloat, opacity: CGFloat, compact: Bool) {
        if GlassMediaExclusion.shouldSkipGlass(for: host) { return }
        let dark = true
        let effect = blurEffect(style: style, dark: dark, intensity: intensity)

        // Always compact for chrome hosts — no full-width slabs
        installCompactPlate(into: host, effect: effect, style: style, intensity: intensity, opacity: opacity)
    }

    // MARK: - Curved compact plate only

    private func installCompactPlate(into host: UIView, effect: UIBlurEffect, style: String, intensity: CGFloat, opacity: CGFloat) {
        let b = host.bounds
        guard b.width > 50, b.height > 24 else { return }

        // Prefer GlassBubbleKit dock for tab bars
        if host is UITabBar || NSStringFromClass(type(of: host)).lowercased().contains("igtabbar") {
            return // GlassDock owns tab presentation
        }
        if host is UINavigationBar || NSStringFromClass(type(of: host)).lowercased().contains("ignavigationbar") {
            return // GlassNavChrome owns nav presentation (capsules only)
        }

        let plate: UIVisualEffectView
        if let e = host.viewWithTag(plateTag) as? UIVisualEffectView {
            plate = e
        } else {
            plate = UIVisualEffectView(effect: effect)
            plate.tag = plateTag
            plate.isUserInteractionEnabled = false
            plate.clipsToBounds = true
            host.insertSubview(plate, at: 0)
        }
        plate.effect = effect

        let side: CGFloat = 14
        let plateH: CGFloat = min(48, b.height * 0.85)
        let y = (b.height - plateH) * 0.5
        plate.frame = CGRect(x: side, y: y, width: b.width - side * 2, height: plateH)
        plate.layer.cornerRadius = plateH * 0.48
        if #available(iOS 13.0, *) { plate.layer.cornerCurve = .continuous }
        plate.alpha = max(0.88, min(1, opacity))
        plate.isHidden = false

        applyInnerLayers(to: plate, style: style, intensity: intensity, compact: true)
        raiseChromeControls(in: host)
    }

    private func applyInnerLayers(to plate: UIVisualEffectView, style: String, intensity: CGFloat, compact: Bool) {
        let cv = plate.contentView

        let tint: UIView
        if let t = cv.viewWithTag(tintTag) { tint = t }
        else {
            tint = UIView(); tint.tag = tintTag; tint.isUserInteractionEnabled = false
            cv.insertSubview(tint, at: 0)
        }
        tint.frame = cv.bounds
        tint.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let frost: CGFloat
        switch style.lowercased() {
        case "clear": frost = 0.08
        case "tinted": frost = 0.24
        case "liquid", "heavy": frost = 0.20
        default: frost = 0.15
        }
        tint.backgroundColor = UIColor(white: 1.0, alpha: frost * max(0.5, intensity))

        let rim: UIView
        if let r = cv.viewWithTag(rimTag) { rim = r }
        else {
            rim = UIView(); rim.tag = rimTag; rim.isUserInteractionEnabled = false
            cv.addSubview(rim)
        }
        let inset: CGFloat = compact ? 8 : 0
        rim.frame = CGRect(x: inset, y: 0.4, width: max(0, cv.bounds.width - inset * 2), height: 0.65)
        rim.autoresizingMask = [.flexibleWidth]
        rim.backgroundColor = UIColor.white.withAlphaComponent(0.38 * intensity)

        let edge: UIView
        if let e = cv.viewWithTag(edgeTag) { edge = e }
        else {
            edge = UIView(); edge.tag = edgeTag; edge.isUserInteractionEnabled = false
            cv.addSubview(edge)
        }
        edge.frame = CGRect(x: inset, y: max(0, cv.bounds.height - 0.55), width: max(0, cv.bounds.width - inset * 2), height: 0.55)
        edge.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        edge.backgroundColor = UIColor.black.withAlphaComponent(0.16 * intensity)

        let bloom: UIView
        if let b = cv.viewWithTag(bloomTag) { bloom = b }
        else {
            bloom = UIView(); bloom.tag = bloomTag; bloom.isUserInteractionEnabled = false
            cv.insertSubview(bloom, at: 1)
        }
        bloom.frame = cv.bounds
        bloom.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bloom.backgroundColor = UIColor(white: 1.0, alpha: 0.035 * intensity)
    }

    private func raiseChromeControls(in host: UIView) {
        for sub in host.subviews {
            if sub.tag == plateTag { continue }
            host.bringSubviewToFront(sub)
        }
    }

    // MARK: - Neutralize stock chrome (clear native bars)

    @objc public func neutralizeStockChrome(_ view: UIView) {
        view.backgroundColor = .clear
        view.isOpaque = false
        view.layer.backgroundColor = UIColor.clear.cgColor
        view.layer.shadowOpacity = 0
        view.layer.borderWidth = 0

        if let tab = view as? UITabBar {
            let a = UITabBarAppearance()
            a.configureWithTransparentBackground()
            a.backgroundEffect = nil
            a.backgroundColor = .clear
            a.shadowColor = .clear
            tab.standardAppearance = a
            tab.scrollEdgeAppearance = a
            tab.isTranslucent = true
            tab.barTintColor = .clear
            tab.backgroundImage = UIImage()
            tab.shadowImage = UIImage()
        }
        if let nav = view as? UINavigationBar {
            let a = UINavigationBarAppearance()
            a.configureWithTransparentBackground()
            a.backgroundEffect = nil
            a.backgroundColor = .clear
            a.shadowColor = .clear
            nav.standardAppearance = a
            nav.scrollEdgeAppearance = a
            nav.compactAppearance = a
            if #available(iOS 15.0, *) { nav.compactScrollEdgeAppearance = a }
            nav.isTranslucent = true
            nav.barTintColor = .clear
            nav.setBackgroundImage(UIImage(), for: .default)
            nav.shadowImage = UIImage()
        }

        // Kill opaque stock plates that redraw black bars
        for sub in view.subviews {
            if sub.tag == plateTag || sub.tag == tintTag || sub.tag == rimTag
                || sub.tag == edgeTag || sub.tag == bloomTag { continue }
            if sub.tag == GlassBubbleKit.dockTag || sub.tag == GlassBubbleKit.selectedTag { continue }
            if sub.tag >= GlassBubbleKit.navBubbleTag && sub.tag < GlassBubbleKit.navBubbleTag &+ 16 { continue }

            let sn = NSStringFromClass(type(of: sub)).lowercased()
            if sn.contains("background") || sn.contains("barbackground") || sn.contains("backdrop")
                || sn.contains("_uibar") || sn.contains("shadowview") {
                sub.backgroundColor = .clear
                sub.isOpaque = false
                sub.alpha = 0
            }
            // Remove foreign visual effect views (not ours)
            if sub is UIVisualEffectView
                && sub.tag != plateTag
                && sub.tag != GlassBubbleKit.dockTag
                && !(sub.tag >= GlassBubbleKit.navBubbleTag && sub.tag < GlassBubbleKit.navBubbleTag &+ 16) {
                sub.removeFromSuperview()
                continue
            }
            if sub.subviews.isEmpty, !(sub is UIControl), !(sub is UIImageView), !(sub is UILabel),
               sub.bounds.width >= view.bounds.width - 4 {
                if let bg = sub.backgroundColor, bg.cgColor.alpha > 0.7 {
                    sub.backgroundColor = .clear
                    sub.isOpaque = false
                }
            }
        }
    }
}
