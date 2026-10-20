import UIKit

@objc public final class GlossyGlassAPI: NSObject {
    @objc public static let shared = GlossyGlassAPI()
    @objc public static let apiVersion: Int = 53
    @objc public static let apiVersionString = "5.3.0"

    @objc public func setEnabled(_ v: Bool) { GlassPreferences.shared.isEnabled = v }
    @objc public func setGlossyMode(_ v: Bool) { GlassPreferences.shared.glossyMode = v }
    @objc public func setIntensity(_ v: CGFloat) { GlassPreferences.shared.intensity = max(0.3, min(1.0, v)) }
    @objc public func setOpacity(_ v: CGFloat) { GlassPreferences.shared.opacity = max(0.3, min(1.0, v)) }

    @objc public func presentSettings() {
        if GlassPreferences.shared.glossyMode { GlassPanelGlossy.shared.present() }
        else { GlassPanel.shared.present() }
    }

    @objc public func forceApply() { GlassChrome.shared.apply(reason: "api") }

    @objc public func diagnostics() -> [String: Any] {
        let p = GlassPreferences.shared
        return [
            "version": Self.apiVersionString,
            "api": Self.apiVersion,
            "enabled": p.isEnabled,
            "glossyMode": p.glossyMode,
            "intensity": p.intensity,
            "opacity": p.opacity,
            "safeMode": p.safeMode
        ]
    }
}
