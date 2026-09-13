import UIKit

/// Central look recipes — “iOS 26-inspired” liquid glass on 17–18
@objc public class GlassThemeEngine: NSObject {

    @objc public static let shared = GlassThemeEngine()

    @objc public func applyLiquidDefault() {
        let p = GlassPreferences.shared
        p.style = "Frosted"
        p.intensity = 0.62
        p.lightIntensity = 0.58
        p.darkIntensity = 0.70
        p.opacity = 0.88
        p.blurEnabled = true
        p.vibrancyEnabled = true
        p.noiseEnabled = false
        p.lightBloomEnabled = true
        p.edgeHighlightEnabled = true
        p.cornerRadius = 22
        p.saturation = 0.55
        p.dimming = 0.12
        p.lightweightMode = false
        p.styleNavigationBar = true
        p.styleTabBar = true
        p.styleButtons = true
        p.styleCards = true
    }

    @objc public func applyLiquidHeavy() {
        applyLiquidDefault()
        let p = GlassPreferences.shared
        p.intensity = 0.82
        p.darkIntensity = 0.85
        p.opacity = 0.94
        p.noiseEnabled = true
        p.dimming = 0.18
        p.cornerRadius = 26
    }

    @objc public func materialStyle(forDark dark: Bool, lightweight: Bool) -> UIBlurEffect.Style {
        if lightweight { return .systemUltraThinMaterial }
        if #available(iOS 15.0, *) {
            return dark ? .systemThinMaterialDark : .systemThinMaterialLight
        }
        return dark ? .dark : .light
    }
}
