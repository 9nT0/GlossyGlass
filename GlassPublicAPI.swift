import UIKit

/// GlossyGlass Public API v3.1
/// Full surface for other tweaks, scripts, and advanced control.
@objc public class GlossyGlassAPI: NSObject {

    @objc public static let shared = GlossyGlassAPI()

    /// API version — bump when breaking changes land
    @objc public static let apiVersion: Int = 36
    @objc public static let apiVersionString: String = "3.6.0"

    // MARK: - Enable / Safe mode

    @objc public func setEnabled(_ enabled: Bool) {
        GlassPreferences.shared.isEnabled = enabled
        if enabled { GlassPreferences.shared.safeMode = false }
        NotificationCenter.default.post(name: .glassAPIStateDidChange, object: nil)
    }

    @objc public func isEnabled() -> Bool { GlassPreferences.shared.isEnabled }

    @objc public func enterSafeMode() {
        GlassPreferences.shared.safeMode = true
        GlassInjector.forceRedetect()
        NotificationCenter.default.post(name: .glassAPIStateDidChange, object: nil)
    }

    @objc public func exitSafeMode() {
        GlassPreferences.shared.safeMode = false
        GlassPreferences.shared.crashCount = 0
        GlassInjector.forceRedetect()
        NotificationCenter.default.post(name: .glassAPIStateDidChange, object: nil)
    }

    @objc public func isSafeMode() -> Bool { GlassPreferences.shared.safeMode }

    // MARK: - Presets & style

    @objc public func applyPreset(_ name: String) {
        GlassPreferences.shared.applyPreset(name)
    }

    @objc public func applyPresetEnum(_ preset: GlassPreset) {
        GlassPreferences.shared.applyPreset(preset.rawString)
    }

    @objc public func currentPreset() -> String { GlassPreferences.shared.preset }

    @objc public func setStyle(_ name: String) {
        GlassPreferences.shared.style = name
    }

    @objc public func setStyleEnum(_ style: GlassStyle) {
        GlassPreferences.shared.style = style.rawString
    }

    @objc public func currentStyle() -> String { GlassPreferences.shared.style }

    // MARK: - Intensity / opacity (live)

    @objc public func setIntensity(_ value: CGFloat) {
        GlassPreferences.shared.intensity = value
    }

    @objc public func setLightIntensity(_ value: CGFloat) {
        GlassPreferences.shared.lightIntensity = value
    }

    @objc public func setDarkIntensity(_ value: CGFloat) {
        GlassPreferences.shared.darkIntensity = value
    }

    @objc public func setOpacity(_ value: CGFloat) {
        GlassPreferences.shared.opacity = value
    }

    @objc public func setBlurEnabled(_ on: Bool) { GlassPreferences.shared.blurEnabled = on }
    @objc public func setVibrancyEnabled(_ on: Bool) { GlassPreferences.shared.vibrancyEnabled = on }
    @objc public func setNoiseEnabled(_ on: Bool) { GlassPreferences.shared.noiseEnabled = on }
    @objc public func setBloomEnabled(_ on: Bool) { GlassPreferences.shared.lightBloomEnabled = on }
    @objc public func setEdgeHighlightEnabled(_ on: Bool) { GlassPreferences.shared.edgeHighlightEnabled = on }
    @objc public func setLightweightMode(_ on: Bool) { GlassPreferences.shared.lightweightMode = on }

    // MARK: - Batch apply

    /// Apply a full configuration snapshot at once
    @objc public func applyConfiguration(_ config: GlassConfiguration) {
        let p = GlassPreferences.shared
        p.isEnabled = config.isEnabled
        p.style = config.style.rawString
        p.intensity = config.intensity
        p.opacity = config.opacity
        p.blurEnabled = config.blurEnabled
        p.vibrancyEnabled = config.vibrancyEnabled
        p.noiseEnabled = config.noiseEnabled
        p.lightBloomEnabled = config.lightBloomEnabled
        p.edgeHighlightEnabled = config.edgeHighlightEnabled
        p.cornerRadius = config.cornerRadius
        p.saturation = config.saturation
        p.dimming = config.dimming
        p.lightIntensity = config.lightIntensity
        p.darkIntensity = config.darkIntensity
        p.lightweightMode = config.lightweightMode
        p.customTint = config.customTint
        p.springResponse = config.springResponse
        p.springDamping = config.springDamping
        p.hapticsEnabled = config.hapticsEnabled
        NotificationCenter.default.post(name: .glassAPIStateDidChange, object: nil)
    }

    @objc public func configuration() -> GlassConfiguration {
        GlassConfiguration.fromPreferences()
    }

    // MARK: - UI

    @objc public func presentSettings() { GlassSettingsPresenter.present() }
    @objc public func presentDiagnostics() { GlassDiagnostics.shared.present() }
    @objc public func forceRedetect() { GlassInjector.forceRedetect() }

    @objc public func resetInjectionState() { GlassInjector.resetInjectionState() }

    @objc public func hostAppSummary() -> String { GlassAppSupport.shared.summary() }

    @objc public func isInstagramHost() -> Bool { GlassAppSupport.shared.isInstagram }

    @objc public func diagnosticsJSON() -> String {
        let d = GlassDiagnostics.shared
        let p = GlassPreferences.shared
        let dict: [String: Any] = [
            "glassVersion": d.glassVersion,
            "apiVersion": GlossyGlassAPI.apiVersion,
            "ios": d.iosVersion,
            "device": d.deviceModel,
            "host": GlassAppSupport.shared.bundleId,
            "isInstagram": GlassAppSupport.shared.isInstagram,
            "attached": d.isAttached,
            "score": d.lastScore,
            "hostClass": d.lastHostClass,
            "enabled": p.isEnabled,
            "safeMode": p.safeMode,
            "style": p.style,
            "intensity": p.intensity,
            "opacity": p.opacity
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
              let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }

    // MARK: - Import / Export

    @objc public func exportSettingsJSON() -> String? {
        GlassPreferences.shared.exportSettingsJSON()
    }

    @objc public func importSettingsJSON(_ json: String) -> Bool {
        GlassPreferences.shared.importSettingsJSON(json)
    }

    @objc public func resetStylesOnly() { GlassPreferences.shared.resetStylesOnly() }
    @objc public func resetAll() { GlassPreferences.shared.resetToDefaults() }

    // MARK: - Per-screen profiles

    @objc public func setScreenProfile(_ name: String, forScreen screen: GlassScreen) {
        GlassPreferences.shared.setProfileName(name, for: screen)
    }

    @objc public func screenProfile(forScreen screen: GlassScreen) -> String {
        GlassPreferences.shared.profileName(for: screen)
    }

    /// Apply the stored profile for a logical screen (Feed/Profile/Messages/Settings)
    @objc public func applyScreenProfile(_ screen: GlassScreen) {
        let name = GlassPreferences.shared.profileName(for: screen)
        if name == "Off" {
            setEnabled(false)
        } else {
            setEnabled(true)
            applyPreset(name)
        }
    }

    // MARK: - NEW: Live tint override (Feature A)

    /// Temporary tint that does not persist — other tweaks can flash/theme glass
    @objc public func setLiveTint(_ color: UIColor?) {
        GlassLiveState.shared.liveTint = color
        NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
    }

    @objc public func clearLiveTint() {
        GlassLiveState.shared.liveTint = nil
        NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
    }

    // MARK: - NEW: Focus mode (Feature B)

    /// Dim everything except glass surfaces slightly — for reading/messages
    @objc public func setFocusMode(_ on: Bool) {
        GlassLiveState.shared.focusMode = on
        if on {
            GlassPreferences.shared.dimming = min(1, GlassPreferences.shared.dimming + 0.15)
        }
        NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
        NotificationCenter.default.post(name: .glassAPIStateDidChange, object: nil)
    }

    @objc public func isFocusMode() -> Bool { GlassLiveState.shared.focusMode }

    // MARK: - NEW: Quick themes (Feature C)

    @objc public func applyQuickTheme(_ theme: String) {
        switch theme.lowercased() {
        case "midnight":
            setStyle("Frosted")
            setDarkIntensity(0.75)
            setLightIntensity(0.40)
            setOpacity(0.90)
            setBloomEnabled(true)
            setEdgeHighlightEnabled(true)
            setNoiseEnabled(false)
        case "crystal":
            setStyle("Clear")
            setIntensity(0.45)
            setOpacity(0.70)
            setBloomEnabled(false)
            setEdgeHighlightEnabled(true)
            setNoiseEnabled(false)
        case "smoke":
            setStyle("Tinted")
            setIntensity(0.80)
            setOpacity(0.95)
            setBloomEnabled(true)
            setNoiseEnabled(true)
            setEdgeHighlightEnabled(true)
        case "minimal":
            applyPreset("Performance")
            setEdgeHighlightEnabled(false)
            setBloomEnabled(false)
        default:
            applyPreset("Default")
        }
        NotificationCenter.default.post(name: .glassAPIStateDidChange, object: nil)
    }

    // MARK: - Observe API changes

    /// Listen for `.glassAPIStateDidChange` to react when another tweak drives the API
    @objc public var stateChangeNotificationName: String {
        Notification.Name.glassAPIStateDidChange.rawValue
    }

    // MARK: - Diagnostics snapshot for other tools

    @objc public func diagnosticsSummary() -> String {
        GlassDiagnostics.shared.summary()
    }

    @objc public func deviceTier() -> String {
        GlassDeviceProfiler.currentTierName()
    }
}

/// Ephemeral runtime state (not persisted)
@objc public class GlassLiveState: NSObject {
    @objc public static let shared = GlassLiveState()
    @objc public var liveTint: UIColor? = nil
    @objc public var focusMode: Bool = false
}

public extension Notification.Name {
    static let glassAPIStateDidChange = Notification.Name("GlassAPIStateDidChange")
}
