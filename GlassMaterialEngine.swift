import UIKit

/// Layered glossy glass renderer (iOS 16–18). Not a flat gray wash.
/// BACKDROP → blur → luminance → vibrancy → specular rim → edge → bloom → final
@objc public final class GlassMaterialEngine: NSObject {

    @objc public static let shared = GlassMaterialEngine()

    public struct Spec {
        public var style: String
        public var intensity: CGFloat
        public var opacity: CGFloat
        public var dark: Bool
        public var compact: Bool // curved tab plate vs full nav strip
    }

    private let plateTag = 0x4747_4D41
    private let tintTag = 0x4747_544E
    private let rimTag = 0x4747_524D
    private let edgeTag = 0x4747_4544
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
        // frosted default — chrome material reads more “glass” on dark IG
        return UIBlurEffect(style: dark ? .systemChromeMaterialDark : .systemChromeMaterialLight)
    }

    /// Install full material stack into a host view. `compact` = curved inset plate (tabs).
    @objc public func install(into host: UIView, style: String, intensity: CGFloat, opacity: CGFloat, compact: Bool) {
        if GlassMediaExclusion.shouldSkipGlass(for: host) { return }
        let dark = true // IG chrome is dark-first
        let effect = blurEffect(style: style, dark: dark, intensity: intensity)

        if compact {
            installCompactPlate(into: host, effect: effect, style: style, intensity: intensity, opacity: opacity)
        } else {
            installStrip(into: host, effect: effect, style: style, intensity: intensity, opacity: opacity)
        }
    }

    // MARK: - Curved compact plate (tab bar)

    private func installCompactPlate(into host: UIView, effect: UIBlurEffect, style: String, intensity: CGFloat, opacity: CGFloat) {
        let b = host.bounds
        guard b.width > 50, b.height > 24 else { return }

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

        // Smaller curved plate — ~half previous height — aligned to icon row (top of tab bar)
        let side: CGFloat = 18
        let plateH: CGFloat = 40  // half-size cleaner capsule
        // Icons sit near top of tab bar; center plate on that band
        let topPad: CGFloat = 4
        let y = topPad
        plate.frame = CGRect(x: side, y: y, width: b.width - side * 2, height: plateH)

        let radius = plateH * 0.48  // strong continuous capsule
        plate.layer.cornerRadius = radius
        if #available(iOS 13.0, *) { plate.layer.cornerCurve = .continuous }
        plate.alpha = max(0.92, min(1, opacity))
        plate.isHidden = false

        applyInnerLayers(to: plate, style: style, intensity: intensity, compact: true)

        // Selected lens tighter
        if let tab = host as? UITabBar, let items = tab.items, let sel = tab.selectedItem,
           let idx = items.firstIndex(of: sel) {
            updateSelectedLens(in: host, index: idx, count: items.count)
        }

        // Keep icons/controls above glass, and nudge image views into plate band
        raiseChromeControls(in: host)
        alignTabIcons(in: host, plateFrame: plate.frame)
    }

    private func alignTabIcons(in host: UIView, plateFrame: CGRect) {
        // Softly pull icon-like subviews into the plate vertical center
        let targetMidY = plateFrame.midY
        for sub in host.subviews {
            if sub.tag == plateTag { continue }
            let sn = NSStringFromClass(type(of: sub)).lowercased()
            // UITabBarButton / IG tab item containers
            if sn.contains("button") || sn.contains("tabbar") || sn.contains("item") || sub is UIControl {
                var f = sub.frame
                if f.height < plateFrame.height + 20, f.width < host.bounds.width * 0.28 {
                    f.origin.y = targetMidY - f.height * 0.5
                    // don't fight layout every frame too hard if zero size
                    if f.height > 8 { sub.frame = f }
                }
            }
        }
    }

    // MARK: - Full strip (nav)

    private func installStrip(into host: UIView, effect: UIBlurEffect, style: String, intensity: CGFloat, opacity: CGFloat) {
        let plate: UIVisualEffectView
        if let e = host.viewWithTag(plateTag) as? UIVisualEffectView {
            plate = e
        } else {
            plate = UIVisualEffectView(effect: effect)
            plate.tag = plateTag
            plate.isUserInteractionEnabled = false
            plate.translatesAutoresizingMaskIntoConstraints = false
            host.insertSubview(plate, at: 0)
            NSLayoutConstraint.activate([
                plate.topAnchor.constraint(equalTo: host.topAnchor),
                plate.leadingAnchor.constraint(equalTo: host.leadingAnchor),
                plate.trailingAnchor.constraint(equalTo: host.trailingAnchor),
                plate.bottomAnchor.constraint(equalTo: host.bottomAnchor)
            ])
        }
        plate.effect = effect
        plate.alpha = max(0.88, min(1, opacity))
        plate.layer.cornerRadius = 0
        applyInnerLayers(to: plate, style: style, intensity: intensity, compact: false)
        raiseChromeControls(in: host)
    }

    private func applyInnerLayers(to plate: UIVisualEffectView, style: String, intensity: CGFloat, compact: Bool) {
        let cv = plate.contentView

        // Luminance / tint
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
        case "clear": frost = 0.10
        case "tinted": frost = 0.28
        case "liquid", "heavy": frost = 0.24
        default: frost = 0.18
        }
        tint.backgroundColor = UIColor(white: 1.0, alpha: frost * max(0.55, intensity))

        // Specular rim (top)
        let rim: UIView
        if let r = cv.viewWithTag(rimTag) { rim = r }
        else {
            rim = UIView(); rim.tag = rimTag; rim.isUserInteractionEnabled = false
            cv.addSubview(rim)
        }
        let inset: CGFloat = compact ? 10 : 0
        rim.frame = CGRect(x: inset, y: 0.5, width: max(0, cv.bounds.width - inset * 2), height: 0.7)
        rim.autoresizingMask = [.flexibleWidth]
        rim.backgroundColor = UIColor.white.withAlphaComponent(0.40 * intensity)
        rim.layer.cornerRadius = 0.35

        // Soft bottom edge (depth)
        let edge: UIView
        if let e = cv.viewWithTag(edgeTag) { edge = e }
        else {
            edge = UIView(); edge.tag = edgeTag; edge.isUserInteractionEnabled = false
            cv.addSubview(edge)
        }
        edge.frame = CGRect(x: inset, y: max(0, cv.bounds.height - 0.6), width: max(0, cv.bounds.width - inset * 2), height: 0.6)
        edge.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        edge.backgroundColor = UIColor.black.withAlphaComponent(0.18 * intensity)

        // Subtle bloom wash
        let bloom: UIView
        if let b = cv.viewWithTag(bloomTag) { bloom = b }
        else {
            bloom = UIView(); bloom.tag = bloomTag; bloom.isUserInteractionEnabled = false
            cv.insertSubview(bloom, at: 1)
        }
        bloom.frame = cv.bounds
        bloom.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bloom.backgroundColor = UIColor(white: 1.0, alpha: 0.04 * intensity)
    }

    /// Small selected-tab lens inside compact plate.
    @objc public func updateSelectedLens(in host: UIView, index: Int, count: Int) {
        guard let plate = host.viewWithTag(plateTag) as? UIVisualEffectView, count > 0 else { return }
        let lensTag = 0x4747_4C4E
        let lens: UIView
        if let l = plate.contentView.viewWithTag(lensTag) { lens = l }
        else {
            lens = UIView()
            lens.tag = lensTag
            lens.isUserInteractionEnabled = false
            lens.backgroundColor = UIColor.white.withAlphaComponent(0.16)
            plate.contentView.insertSubview(lens, at: 0)
        }
        let w = plate.bounds.width / CGFloat(count)
        let f = CGRect(
            x: CGFloat(index) * w + w * 0.22,
            y: plate.bounds.height * 0.12,
            width: w * 0.56,
            height: plate.bounds.height * 0.76
        )
        lens.frame = f
        lens.layer.cornerRadius = min(12, f.height * 0.42)
        if #available(iOS 13.0, *) { lens.layer.cornerCurve = .continuous }
        lens.alpha = max(0.5, GlassPreferences.shared.intensity)
    }

    private func raiseChromeControls(in host: UIView) {
        for sub in host.subviews {
            if sub.tag == plateTag { continue }
            host.bringSubviewToFront(sub)
        }
    }

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

        // Aggressive exclusive: kill opaque plates that redraw black bars
        for sub in view.subviews {
            if sub.tag == plateTag || sub.tag == tintTag || sub.tag == rimTag || sub.tag == edgeTag || sub.tag == bloomTag { continue }
            let sn = NSStringFromClass(type(of: sub)).lowercased()
            if sn.contains("background") || sn.contains("barbackground") || sn.contains("backdrop")
                || sn.contains("_uibar") || sn.contains("shadowview") {
                sub.backgroundColor = .clear
                sub.isOpaque = false
                sub.alpha = 0
            }
            if sub is UIVisualEffectView && sub.tag != plateTag {
                sub.removeFromSuperview()
                continue
            }
            // Full-bleed solid black empty views
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

