import UIKit
import CoreImage

/// High-quality liquid glass material engine.
/// Builds real UIVisualEffect / private backdrop / CIFilter stacks — never floating screen overlays.
@objc public final class GlassLiquidEngine: NSObject {

    @objc public static let shared = GlassLiquidEngine()

    private let ci = CIContext(options: [.useSoftwareRenderer: false])
    private var cache: [String: UIVisualEffect] = [:]

    @objc public enum MaterialKind: Int {
        case clear = 0
        case frosted = 1
        case tinted = 2
        case liquid = 3
        case chrome = 4
        case ultraThin = 5
    }

    @objc public func effect(for kind: MaterialKind, dark: Bool) -> UIVisualEffect {
        let key = "\(kind.rawValue)-\(dark)"
        if let c = cache[key] { return c }

        // Prefer real UIGlassEffect when OS provides it
        if GlassPrivateBridge.hasUIGlassEffect {
            if let g = GlassPrivateBridge.makeGlassEffect(clear: kind == .clear || kind == .ultraThin) {
                cache[key] = g
                return g
            }
        }

        let ultra = kind == .ultraThin || kind == .clear
        let e = GlassPrivateBridge.systemChromeMaterial(dark: dark, ultraThin: ultra)
        cache[key] = e
        return e
    }

    
    /// UIBar appearance requires UIBlurEffect specifically (not generic UIVisualEffect).
    @objc public func blurEffectMatchingPreferences(dark: Bool) -> UIBlurEffect {
        let prefs = GlassPreferences.shared
        if prefs.lightweightMode || prefs.style.lowercased() == "clear" {
            return UIBlurEffect(style: dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
        }
        switch prefs.style.lowercased() {
        case "tinted":
            return UIBlurEffect(style: dark ? .systemMaterialDark : .systemMaterialLight)
        case "liquid":
            return UIBlurEffect(style: dark ? .systemThinMaterialDark : .systemThinMaterialLight)
        default:
            return UIBlurEffect(style: dark ? .systemThinMaterialDark : .systemThinMaterialLight)
        }
    }

    @objc public func effectMatchingPreferences(dark: Bool) -> UIVisualEffect {
        let prefs = GlassPreferences.shared
        let kind: MaterialKind
        switch prefs.style.lowercased() {
        case "clear": kind = .clear
        case "tinted": kind = .tinted
        case "liquid": kind = .liquid
        default: kind = prefs.lightweightMode ? .ultraThin : .frosted
        }
        return effect(for: kind, dark: dark)
    }

    /// Apply liquid material to a UINavigationBar via appearance (in-place).
    @objc public func applyToNavigationBar(_ bar: UINavigationBar) {
        GlassNavigationHelper.applyNavigationBarStyle(to: bar)
    }

    @objc public func applyToTabBar(_ bar: UITabBar) {
        GlassNavigationHelper.applyTabBarStyle(to: bar)
    }

    /// Configure a UIVisualEffectView already in hierarchy (no new overlays on window).
    @objc public func configureEffectView(_ view: UIVisualEffectView, dark: Bool) {
        view.effect = effectMatchingPreferences(dark: dark)
        GlassPrivateBridge.setContinuousCorners(view, radius: view.layer.cornerRadius)
    }

    /// Layer-level liquid filters (private CAFilter when available).
    @objc public func applyLiquidFilters(to layer: CALayer, intensity: CGFloat) {
        let prefs = GlassPreferences.shared
        let blur = Float(max(0, (1.0 - intensity) * 2.0))
        let sat = Float(0.85 + prefs.saturation * 0.4)
        let bright = Float((prefs.dimming) * -0.15)
        _ = GlassPrivateBridge.applyLayerFilters(layer, blur: blur, saturate: sat, brightness: bright)
    }

    @objc public func clearFilters(on layer: CALayer) {
        GlassPrivateBridge.clearLayerFilters(layer)
    }

    /// CIFilter pipeline for offline/snapshot gloss (used by diagnostics previews, not screen overlays).
    @objc public func processSnapshot(_ image: UIImage, intensity: CGFloat) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        var ciImage = CIImage(cgImage: cg)
        let sat = CIFilter(name: "CIColorControls")
        sat?.setValue(ciImage, forKey: kCIInputImageKey)
        sat?.setValue(0.9 + intensity * 0.3, forKey: kCIInputSaturationKey)
        sat?.setValue(1.0 - intensity * 0.05, forKey: kCIInputContrastKey)
        if let o = sat?.outputImage { ciImage = o }

        let blur = CIFilter(name: "CIGaussianBlur")
        blur?.setValue(ciImage, forKey: kCIInputImageKey)
        blur?.setValue(max(0.5, intensity * 4), forKey: kCIInputRadiusKey)
        if let o = blur?.outputImage {
            ciImage = o.cropped(to: CIImage(cgImage: cg).extent)
        }

        guard let out = ci.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }

    @objc public func engineReport() -> String {
        """
        LiquidEngine
        UIGlass: \(GlassPrivateBridge.hasUIGlassEffect)
        Backdrop: \(GlassPrivateBridge.hasBackdropView)
        PrefsStyle: \(GlassPreferences.shared.style)
        Cache: \(cache.count)
        \(GlassPrivateBridge.capabilityReport())
        """
    }
}
