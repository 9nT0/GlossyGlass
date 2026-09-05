import UIKit
import Foundation

@objc public class GlassPreferences: NSObject {

    private static let suiteName = "com.glossyglass.preferences"

    private enum Key: String {
        case enabled              = "GG_Enabled"
        case style                = "GG_Style"           // Frosted / Clear / Tinted
        case intensity            = "GG_Intensity"
        case opacity              = "GG_Opacity"
        case blurEnabled          = "GG_BlurEnabled"
        case vibrancyEnabled      = "GG_VibrancyEnabled"
        case noiseEnabled         = "GG_NoiseEnabled"
        case lightBloomEnabled    = "GG_LightBloomEnabled"
        case cornerRadius         = "GG_CornerRadius"
        case saturation           = "GG_Saturation"
        case dimming              = "GG_Dimming"
        case lightIntensity       = "GG_LightIntensity"
        case darkIntensity        = "GG_DarkIntensity"
        case hideGlassButton      = "GG_HideGlassButton"
        case styleNavigationBar   = "GG_StyleNavigationBar"
        case styleTabBar          = "GG_StyleTabBar"
        case styleButtons         = "GG_StyleButtons"
        case styleCards           = "GG_StyleCards"
        case debugLogging         = "GG_DebugLogging"
        case preset               = "GG_Preset"
    }

    @objc public static let shared = GlassPreferences()
    private let defaults: UserDefaults

    private override init() {
        if let suite = UserDefaults(suiteName: GlassPreferences.suiteName) {
            self.defaults = suite
        } else {
            self.defaults = .standard
        }
        super.init()
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Key.enabled.rawValue            : true,
            Key.style.rawValue              : "Frosted",
            Key.intensity.rawValue          : 0.72,
            Key.opacity.rawValue            : 0.85,
            Key.blurEnabled.rawValue        : true,
            Key.vibrancyEnabled.rawValue    : true,
            Key.noiseEnabled.rawValue       : false,
            Key.lightBloomEnabled.rawValue  : true,
            Key.cornerRadius.rawValue       : 24.0,
            Key.saturation.rawValue         : 0.65,
            Key.dimming.rawValue            : 0.30,
            Key.lightIntensity.rawValue     : 0.55,
            Key.darkIntensity.rawValue      : 0.45,
            Key.hideGlassButton.rawValue    : false,
            "GG_LightweightMode"         : false,
            Key.styleNavigationBar.rawValue : true,
            Key.styleTabBar.rawValue        : true,
            Key.styleButtons.rawValue       : true,
            Key.styleCards.rawValue         : true,
            Key.debugLogging.rawValue       : false,
            Key.preset.rawValue             : "Default"
        ])
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
        set { defaults.set(Double(max(0, min(1, newValue))), forKey: Key.intensity.rawValue); notifyChange() }
    }

    @objc public var opacity: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.opacity.rawValue)) }
        set { defaults.set(Double(max(0, min(1, newValue))), forKey: Key.opacity.rawValue); notifyChange() }
    }

    // MARK: - Effects

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

    // MARK: - Advanced

    @objc public var cornerRadius: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.cornerRadius.rawValue)) }
        set { defaults.set(Double(newValue), forKey: Key.cornerRadius.rawValue); notifyChange() }
    }

    @objc public var saturation: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.saturation.rawValue)) }
        set { defaults.set(Double(max(0, min(1, newValue))), forKey: Key.saturation.rawValue); notifyChange() }
    }

    @objc public var dimming: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.dimming.rawValue)) }
        set { defaults.set(Double(max(0, min(1, newValue))), forKey: Key.dimming.rawValue); notifyChange() }
    }

    // MARK: - Extra

    @objc public var lightIntensity: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.lightIntensity.rawValue)) }
        set { defaults.set(Double(max(0, min(1, newValue))), forKey: Key.lightIntensity.rawValue); notifyChange() }
    }

    @objc public var darkIntensity: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.darkIntensity.rawValue)) }
        set { defaults.set(Double(max(0, min(1, newValue))), forKey: Key.darkIntensity.rawValue); notifyChange() }
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


    // MARK: - Compatibility aliases (used by GlassView / NavHelper / etc.)

    @objc public var glossIntensity: CGFloat {
        get { intensity }
        set { intensity = newValue }
    }

    @objc public var lightweightMode: Bool {
        get { defaults.bool(forKey: "GG_LightweightMode") }
        set {
            defaults.set(newValue, forKey: "GG_LightweightMode")
            notifyChange()
        }
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

    // MARK: - Presets

    @objc public func applyPreset(_ name: String) {
        preset = name
        switch name {
        case "Clean":
            style = "Clear"; intensity = 0.40; opacity = 0.70
            blurEnabled = true; vibrancyEnabled = false; noiseEnabled = false; lightBloomEnabled = false
            cornerRadius = 20; saturation = 0.40; dimming = 0.15
        case "Heavy":
            style = "Frosted"; intensity = 0.90; opacity = 0.95
            blurEnabled = true; vibrancyEnabled = true; noiseEnabled = true; lightBloomEnabled = true
            cornerRadius = 28; saturation = 0.80; dimming = 0.45
        case "Performance":
            style = "Clear"; intensity = 0.35; opacity = 0.60
            blurEnabled = false; vibrancyEnabled = false; noiseEnabled = false; lightBloomEnabled = false
            cornerRadius = 18; saturation = 0.30; dimming = 0.10
        default: // Default
            style = "Frosted"; intensity = 0.72; opacity = 0.85
            blurEnabled = true; vibrancyEnabled = true; noiseEnabled = false; lightBloomEnabled = true
            cornerRadius = 24; saturation = 0.65; dimming = 0.30
        }
        notifyChange()
    }

    @objc public func resetToDefaults() {
        let domain = defaults.dictionaryRepresentation().keys
        domain.forEach { defaults.removeObject(forKey: $0) }
        registerDefaults()
        notifyChange()
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
        if debugLogging {
            print("[GlossyGlass] Preferences updated")
        }
    }

    @objc public func log(_ message: String) {
        guard debugLogging else { return }
        print("[GlossyGlass] \(message)")
    }
}

public extension Notification.Name {
    static let glassPreferencesDidChange = Notification.Name("GlassPreferencesDidChange")
}


// MARK: - UIColor hex helpers

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
        default:
            return nil
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
