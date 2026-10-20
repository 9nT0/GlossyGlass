//
//  GlossyGlassAPI.swift
//  GlossyGlass v5
//
//  Public API so other tweaks or scripts can control the engine.
//

import UIKit

@objc public final class GlossyGlassAPI: NSObject {

    @objc public static let shared = GlossyGlassAPI()

    @objc public static let apiVersion: Int = 50
    @objc public static let apiVersionString = "5.0.0"

    // MARK: - Enable / Disable

    @objc public func setEnabled(_ enabled: Bool) {
        GlassPreferences.shared.isEnabled = enabled
    }

    @objc public func setGlossyMode(_ enabled: Bool) {
        GlassPreferences.shared.glossyMode = enabled
    }

    // MARK: - Appearance

    @objc public func setIntensity(_ value: CGFloat) {
        GlassPreferences.shared.intensity = max(0.3, min(1.0, value))
    }

    @objc public func setOpacity(_ value: CGFloat) {
        GlassPreferences.shared.opacity = max(0.3, min(1.0, value))
    }

    // MARK: - Panel

    @objc public func presentSettings() {
        if GlassPreferences.shared.glossyMode {
            GlassPanelGlossy.shared.present()
        } else {
            GlassPanel.shared.present()
        }
    }

    // MARK: - Force refresh

    @objc public func forceApply() {
        GlassChrome.shared.apply(reason: "api")
    }

    // MARK: - Diagnostics (simple)

    @objc public func diagnostics() -> [String: Any] {
        let prefs = GlassPreferences.shared
        return [
            "version": Self.apiVersionString,
            "enabled": prefs.isEnabled,
            "glossyMode": prefs.glossyMode,
            "intensity": prefs.intensity,
            "opacity": prefs.opacity,
            "safeMode": prefs.safeMode
        ]
    }
}
