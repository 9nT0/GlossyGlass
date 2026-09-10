import UIKit
import Foundation

@objc public class GlassPreferences: NSObject {

    private static let suiteName = "com.glossyglass.preferences"
    private static let currentSettingsVersion = 3

    private enum Key: String {
        case settingsVersion      = "GG_SettingsVersion"
        case enabled              = "GG_Enabled"
        case style                = "GG_Style"
        case intensity            = "GG_Intensity"
        case opacity              = "GG_Opacity"
        case blurEnabled          = "GG_BlurEnabled"
        case vibrancyEnabled      = "GG_VibrancyEnabled"
        case noiseEnabled         = "GG_NoiseEnabled"
        case lightBloomEnabled    = "GG_LightBloomEnabled"
        case edgeHighlightEnabled = "GG_EdgeHighlightEnabled"
        case cornerRadius         = "GG_CornerRadius"
        case saturation           = "GG_Saturation"
        case dimming              = "GG_Dimming"
        case lightIntensity       = "GG_LightIntensity"
        case darkIntensity        = "GG_DarkIntensity"
        case hideGlassButton      = "GG_HideGlassButton"
        case forceShowGlassButton = "GG_ForceShowGlassButton"
        case exclusiveChrome      = "GG_ExclusiveChrome"
        case autoApplyScreenProfiles = "GG_AutoApplyScreenProfiles"
        case lastButtonX = "GG_LastButtonX"
        case lastButtonY = "GG_LastButtonY"
        case styleNavigationBar   = "GG_StyleNavigationBar"
        case styleTabBar          = "GG_StyleTabBar"
        case styleButtons         = "GG_StyleButtons"
        case styleCards           = "GG_StyleCards"
        case debugLogging         = "GG_DebugLogging"
        case preset               = "GG_Preset"
        case springResponse       = "GG_SpringResponse"
        case springDamping        = "GG_SpringDamping"
        case hapticsEnabled       = "GG_HapticsEnabled"
        case safeMode             = "GG_SafeMode"
        case crashCount           = "GG_CrashCount"
        case screenProfileFeed    = "GG_Screen_Feed"
        case screenProfileProfile = "GG_Screen_Profile"
        case screenProfileMessages = "GG_Screen_Messages"
        case screenProfileSettings = "GG_Screen_Settings"
    }

    @objc public static let shared = GlassPreferences()
    private let defaults: UserDefaults
    private var notifyWorkItem: DispatchWorkItem?

    private override init() {
        if let suite = UserDefaults(suiteName: GlassPreferences.suiteName) {
            self.defaults = suite
        } else {
            self.defaults = .standard
        }
        super.init()
        registerDefaults()
        migrateIfNeeded()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Key.settingsVersion.rawValue    : GlassPreferences.currentSettingsVersion,
            Key.enabled.rawValue            : true,
            Key.style.rawValue              : "Frosted",
            Key.intensity.rawValue          : 0.72,
            Key.opacity.rawValue            : 0.85,
            Key.blurEnabled.rawValue        : true,
            Key.vibrancyEnabled.rawValue    : true,
            Key.noiseEnabled.rawValue       : false,
            Key.lightBloomEnabled.rawValue  : true,
            Key.edgeHighlightEnabled.rawValue : true,
            Key.cornerRadius.rawValue       : 24.0,
            Key.saturation.rawValue         : 0.65,
            Key.dimming.rawValue            : 0.30,
            Key.lightIntensity.rawValue     : 0.55,
            Key.darkIntensity.rawValue      : 0.45,
            Key.hideGlassButton.rawValue    : false,
            Key.forceShowGlassButton.rawValue : false,
            Key.exclusiveChrome.rawValue     : true,
            Key.autoApplyScreenProfiles.rawValue : false,
            Key.lastButtonX.rawValue : -1.0,
            Key.lastButtonY.rawValue : -1.0,
            "GG_LightweightMode"            : false,
            Key.styleNavigationBar.rawValue : true,
            Key.styleTabBar.rawValue        : true,
            Key.styleButtons.rawValue       : true,
            Key.styleCards.rawValue         : true,
            Key.debugLogging.rawValue       : false,
            Key.preset.rawValue             : "Default",
            Key.springResponse.rawValue     : 0.28,
            Key.springDamping.rawValue      : 0.72,
            Key.hapticsEnabled.rawValue     : true,
            Key.safeMode.rawValue           : false,
            Key.crashCount.rawValue         : 0,
            Key.screenProfileFeed.rawValue  : "Default",
            Key.screenProfileProfile.rawValue : "Heavy",
            Key.screenProfileMessages.rawValue : "Clear",
            Key.screenProfileSettings.rawValue : "Off"
        ])
    }

    // MARK: - Migration

    private func migrateIfNeeded() {
        let version = defaults.integer(forKey: Key.settingsVersion.rawValue)
        if version < 2 {
            // v1 → v2: map old gloss intensity
            if defaults.object(forKey: "GG_GlossIntensity") != nil {
                let old = defaults.double(forKey: "GG_GlossIntensity")
                intensity = CGFloat(old)
                lightIntensity = CGFloat(old)
                darkIntensity = CGFloat(old) * 0.85
            }
        }
        if version < 4 {
            // v2 → v3: ensure new keys exist with sane defaults
            if defaults.object(forKey: Key.edgeHighlightEnabled.rawValue) == nil {
                edgeHighlightEnabled = true
            }
            if defaults.object(forKey: Key.springResponse.rawValue) == nil {
                springResponse = 0.28
                springDamping = 0.72
            }
        }
        defaults.set(GlassPreferences.currentSettingsVersion, forKey: Key.settingsVersion.rawValue)
    }

    // MARK: - Core

    @objc public var isEnabled: Bool {
        get { defaults.bool(forKey: Key.enabled.rawValue) }
        set { defaults.set(newValue, forKey: Key.enabled.rawValue); notifyChange() }
    }

    @objc public var style: String {
        get { defaults.string(forKey: Key.style.rawValue) ?? "Frosted" }
        set { defaults.set(newValue, forKey: Key.style.rawValue); notifyChange() }
    }

    @objc public var intensity: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.intensity.rawValue)) }
        set { defaults.set(Double(clamp01(newValue)), forKey: Key.intensity.rawValue); notifyChangeDebounced() }
    }

    @objc public var opacity: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.opacity.rawValue)) }
        set { defaults.set(Double(clamp01(newValue)), forKey: Key.opacity.rawValue); notifyChangeDebounced() }
    }

    @objc public var blurEnabled: Bool {
        get { defaults.bool(forKey: Key.blurEnabled.rawValue) }
        set { defaults.set(newValue, forKey: Key.blurEnabled.rawValue); notifyChange() }
    }

    @objc public var vibrancyEnabled: Bool {
        get { defaults.bool(forKey: Key.vibrancyEnabled.rawValue) }
        set { defaults.set(newValue, forKey: Key.vibrancyEnabled.rawValue); notifyChange() }
    }

    @objc public var noiseEnabled: Bool {
        get { defaults.bool(forKey: Key.noiseEnabled.rawValue) }
        set { defaults.set(newValue, forKey: Key.noiseEnabled.rawValue); notifyChange() }
    }

    @objc public var lightBloomEnabled: Bool {
        get { defaults.bool(forKey: Key.lightBloomEnabled.rawValue) }
        set { defaults.set(newValue, forKey: Key.lightBloomEnabled.rawValue); notifyChange() }
    }

    @objc public var edgeHighlightEnabled: Bool {
        get { defaults.bool(forKey: Key.edgeHighlightEnabled.rawValue) }
        set { defaults.set(newValue, forKey: Key.edgeHighlightEnabled.rawValue); notifyChange() }
    }

    @objc public var cornerRadius: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.cornerRadius.rawValue)) }
        set { defaults.set(Double(max(0, min(40, newValue))), forKey: Key.cornerRadius.rawValue); notifyChangeDebounced() }
    }

    @objc public var saturation: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.saturation.rawValue)) }
        set { defaults.set(Double(clamp01(newValue)), forKey: Key.saturation.rawValue); notifyChangeDebounced() }
    }

    @objc public var dimming: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.dimming.rawValue)) }
        set { defaults.set(Double(clamp01(newValue)), forKey: Key.dimming.rawValue); notifyChangeDebounced() }
    }

    @objc public var lightIntensity: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.lightIntensity.rawValue)) }
        set { defaults.set(Double(clamp01(newValue)), forKey: Key.lightIntensity.rawValue); notifyChangeDebounced() }
    }

    @objc public var darkIntensity: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.darkIntensity.rawValue)) }
        set { defaults.set(Double(clamp01(newValue)), forKey: Key.darkIntensity.rawValue); notifyChangeDebounced() }
    }

    @objc public var hideGlassButton: Bool {
        get { defaults.bool(forKey: Key.hideGlassButton.rawValue) }
        set { defaults.set(newValue, forKey: Key.hideGlassButton.rawValue); notifyChange() }
    }

    @objc public var styleNavigationBar: Bool {
        get { defaults.bool(forKey: Key.styleNavigationBar.rawValue) }
        set { defaults.set(newValue, forKey: Key.styleNavigationBar.rawValue); notifyChange() }
    }

    @objc public var styleTabBar: Bool {
        get { defaults.bool(forKey: Key.styleTabBar.rawValue) }
        set { defaults.set(newValue, forKey: Key.styleTabBar.rawValue); notifyChange() }
    }

    @objc public var styleButtons: Bool {
        get { defaults.bool(forKey: Key.styleButtons.rawValue) }
        set { defaults.set(newValue, forKey: Key.styleButtons.rawValue); notifyChange() }
    }

    @objc public var styleCards: Bool {
        get { defaults.bool(forKey: Key.styleCards.rawValue) }
        set { defaults.set(newValue, forKey: Key.styleCards.rawValue); notifyChange() }
    }

    @objc public var debugLogging: Bool {
        get { defaults.bool(forKey: Key.debugLogging.rawValue) }
        set { defaults.set(newValue, forKey: Key.debugLogging.rawValue) }
    }

    @objc public var preset: String {
        get { defaults.string(forKey: Key.preset.rawValue) ?? "Default" }
        set { defaults.set(newValue, forKey: Key.preset.rawValue) }
    }

    @objc public var springResponse: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.springResponse.rawValue)) }
        set { defaults.set(Double(max(0.1, min(1.0, newValue))), forKey: Key.springResponse.rawValue); notifyChange() }
    }

    @objc public var springDamping: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.springDamping.rawValue)) }
        set { defaults.set(Double(max(0.2, min(1.0, newValue))), forKey: Key.springDamping.rawValue); notifyChange() }
    }

    @objc public var hapticsEnabled: Bool {
        get { defaults.bool(forKey: Key.hapticsEnabled.rawValue) }
        set { defaults.set(newValue, forKey: Key.hapticsEnabled.rawValue); notifyChange() }
    }

    @objc public var safeMode: Bool {
        get { defaults.bool(forKey: Key.safeMode.rawValue) }
        set { defaults.set(newValue, forKey: Key.safeMode.rawValue); notifyChange() }
    }

    @objc public var crashCount: Int {
        get { defaults.integer(forKey: Key.crashCount.rawValue) }
        set { defaults.set(newValue, forKey: Key.crashCount.rawValue) }
    }


    @objc public var exclusiveChrome: Bool {
        get { defaults.object(forKey: Key.exclusiveChrome.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.exclusiveChrome.rawValue); notifyChange() }
    }

    @objc public var forceShowGlassButton: Bool {
        get { defaults.bool(forKey: Key.forceShowGlassButton.rawValue) }
        set { defaults.set(newValue, forKey: Key.forceShowGlassButton.rawValue); notifyChange() }
    }

    @objc public var autoApplyScreenProfiles: Bool {
        get { defaults.bool(forKey: Key.autoApplyScreenProfiles.rawValue) }
        set { defaults.set(newValue, forKey: Key.autoApplyScreenProfiles.rawValue); notifyChange() }
    }

    @objc public var lastButtonPoint: CGPoint {
        get {
            let x = defaults.double(forKey: Key.lastButtonX.rawValue)
            let y = defaults.double(forKey: Key.lastButtonY.rawValue)
            if x < 0 || y < 0 { return CGPoint(x: -1, y: -1) }
            return CGPoint(x: x, y: y)
        }
        set {
            defaults.set(Double(newValue.x), forKey: Key.lastButtonX.rawValue)
            defaults.set(Double(newValue.y), forKey: Key.lastButtonY.rawValue)
        }
    }

    // MARK: - Compatibility aliases

    @objc public var glossIntensity: CGFloat {
        get { intensity }
        set { intensity = newValue }
    }

    @objc public var lightweightMode: Bool {
        get { defaults.bool(forKey: "GG_LightweightMode") }
        set { defaults.set(newValue, forKey: "GG_LightweightMode"); notifyChange() }
    }

    @objc public var customTint: UIColor? {
        get {
            guard let hex = defaults.string(forKey: "GG_CustomTintHex"), !hex.isEmpty else { return nil }
            return UIColor(ggHex: hex)
        }
        set {
            if let color = newValue {
                defaults.set(color.ggToHex(), forKey: "GG_CustomTintHex")
            } else {
                defaults.set("", forKey: "GG_CustomTintHex")
            }
            notifyChange()
        }
    }

    // MARK: - Per-screen profiles

    @objc public func profileName(for screen: GlassScreen) -> String {
        switch screen {
        case .feed: return defaults.string(forKey: Key.screenProfileFeed.rawValue) ?? "Default"
        case .profile: return defaults.string(forKey: Key.screenProfileProfile.rawValue) ?? "Heavy"
        case .messages: return defaults.string(forKey: Key.screenProfileMessages.rawValue) ?? "Clear"
        case .settings: return defaults.string(forKey: Key.screenProfileSettings.rawValue) ?? "Off"
        default: return preset
        }
    }

    @objc public func setProfileName(_ name: String, for screen: GlassScreen) {
        switch screen {
        case .feed: defaults.set(name, forKey: Key.screenProfileFeed.rawValue)
        case .profile: defaults.set(name, forKey: Key.screenProfileProfile.rawValue)
        case .messages: defaults.set(name, forKey: Key.screenProfileMessages.rawValue)
        case .settings: defaults.set(name, forKey: Key.screenProfileSettings.rawValue)
        default: break
        }
        notifyChange()
    }

    // MARK: - Presets

    @objc public func applyPreset(_ name: String) {
        preset = name
        switch name {
        case "Clean":
            style = "Clear"; intensity = 0.40; opacity = 0.70
            blurEnabled = true; vibrancyEnabled = false; noiseEnabled = false
            lightBloomEnabled = false; edgeHighlightEnabled = true
            cornerRadius = 20; saturation = 0.40; dimming = 0.15
            lightIntensity = 0.45; darkIntensity = 0.35; lightweightMode = true
        case "Heavy":
            style = "Frosted"; intensity = 0.90; opacity = 0.95
            blurEnabled = true; vibrancyEnabled = true; noiseEnabled = true
            lightBloomEnabled = true; edgeHighlightEnabled = true
            cornerRadius = 28; saturation = 0.80; dimming = 0.45
            lightIntensity = 0.70; darkIntensity = 0.55; lightweightMode = false
        case "Performance":
            style = "Clear"; intensity = 0.28; opacity = 0.55
            blurEnabled = false; vibrancyEnabled = false; noiseEnabled = false
            lightBloomEnabled = false; edgeHighlightEnabled = false
            cornerRadius = 16; saturation = 0.25; dimming = 0.08
            lightIntensity = 0.28; darkIntensity = 0.22; lightweightMode = true
            springResponse = 0.20; springDamping = 0.90
        case "Off":
            isEnabled = false
        default:
            style = "Frosted"; intensity = 0.72; opacity = 0.85
            blurEnabled = true; vibrancyEnabled = true; noiseEnabled = false
            lightBloomEnabled = true; edgeHighlightEnabled = true
            cornerRadius = 24; saturation = 0.65; dimming = 0.30
            lightIntensity = 0.55; darkIntensity = 0.45; lightweightMode = false
            isEnabled = true
        }
        notifyChange()
    }

    @objc public func resetToDefaults() {
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("GG_") }
        keys.forEach { defaults.removeObject(forKey: $0) }
        registerDefaults()
        notifyChange()
    }

    @objc public func resetStylesOnly() {
        style = "Frosted"
        intensity = 0.72
        opacity = 0.85
        blurEnabled = true
        vibrancyEnabled = true
        noiseEnabled = false
        lightBloomEnabled = true
        edgeHighlightEnabled = true
        cornerRadius = 24
        saturation = 0.65
        dimming = 0.30
        lightIntensity = 0.55
        darkIntensity = 0.45
        notifyChange()
    }

    // MARK: - Export / Import (JSON)

    @objc public func exportSettings() -> [String: Any] {
        var dict: [String: Any] = [:]
        for (key, value) in defaults.dictionaryRepresentation() {
            if key.hasPrefix("GG_") {
                dict[key] = value
            }
        }
        return dict
    }

    @objc public func exportSettingsJSON() -> String? {
        let dict = exportSettings()
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @objc public func importSettings(_ dict: [String: Any]) {
        for (key, value) in dict where key.hasPrefix("GG_") {
            defaults.set(value, forKey: key)
        }
        migrateIfNeeded()
        notifyChange()
    }

    @objc public func importSettingsJSON(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        importSettings(dict)
        return true
    }

    // MARK: - Notify (debounced for sliders)

    private func notifyChange() {
        notifyWorkItem?.cancel()
        NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
        GlassSyncBus.shared.publishPreferencesChanged()
        GlassChromeCoordinator.shared.apply(reason: "prefs")
        if debugLogging { print("[GlossyGlass] Preferences updated") }
    }

    private func notifyChangeDebounced() {
        notifyWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
            if self?.debugLogging == true { print("[GlossyGlass] Preferences updated (debounced)") }
        }
        notifyWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
    }

    @objc public func log(_ message: String) {
        guard debugLogging else { return }
        print("[GlossyGlass] \(message)")
    }

    private func clamp01(_ v: CGFloat) -> CGFloat { max(0, min(1, v)) }
}

public extension Notification.Name {
    static let glassPreferencesDidChange = Notification.Name("GlassPreferencesDidChange")
}

private extension UIColor {
    convenience init?(ggHex: String) {
        var hex = ggHex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex.removeFirst() }
        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else { return nil }
        let r, g, b, a: CGFloat
        switch hex.count {
        case 6:
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255
            b = CGFloat(rgb & 0x0000FF) / 255
            a = 1.0
        case 8:
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255
            a = CGFloat(rgb & 0x000000FF) / 255
        default: return nil
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    func ggToHex() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255)
        return String(format: "#%06x", rgb)
    }
}
