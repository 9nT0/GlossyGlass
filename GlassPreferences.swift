import UIKit
import Foundation

/// Advanced preferences for GlossyGlass v2
@objc public class GlassPreferences: NSObject {

    private static let suiteName = "com.glossyglass.preferences"

    private enum Key: String {
        case enabled              = "GG_Enabled"
        case glossIntensity       = "GG_GlossIntensity"
        case lightIntensity       = "GG_LightIntensity"
        case darkIntensity        = "GG_DarkIntensity"
        case useCustomTint        = "GG_UseCustomTint"
        case customTintHex        = "GG_CustomTintHex"
        case lightweightMode      = "GG_LightweightMode"
        case glassMode            = "GG_GlassMode"          // 0=Frosted, 1=Clear, 2=Tinted
        case styleNavigationBar   = "GG_StyleNavigationBar"
        case styleTabBar          = "GG_StyleTabBar"
        case styleButtons         = "GG_StyleButtons"
        case styleCards           = "GG_StyleCards"
        case showGlassButton      = "GG_ShowGlassButton"
        case springResponse       = "GG_SpringResponse"
        case springDamping        = "GG_SpringDamping"
        case debugLogging         = "GG_DebugLogging"
        case debugOverlay         = "GG_DebugOverlay"
        case activeProfile        = "GG_ActiveProfile"
        case chromaticAberration  = "GG_ChromaticAberration"
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
            Key.glossIntensity.rawValue     : 0.55,
            Key.lightIntensity.rawValue     : 0.55,
            Key.darkIntensity.rawValue      : 0.40,
            Key.useCustomTint.rawValue      : false,
            Key.customTintHex.rawValue      : "",
            Key.lightweightMode.rawValue    : false,
            Key.glassMode.rawValue          : 0,
            Key.styleNavigationBar.rawValue : true,
            Key.styleTabBar.rawValue        : true,
            Key.styleButtons.rawValue       : true,
            Key.styleCards.rawValue         : true,
            Key.showGlassButton.rawValue    : true,
            Key.springResponse.rawValue     : 0.28,
            Key.springDamping.rawValue      : 0.72,
            Key.debugLogging.rawValue       : false,
            Key.debugOverlay.rawValue       : false,
            Key.activeProfile.rawValue      : "Default",
            Key.chromaticAberration.rawValue: false
        ])
    }

    // MARK: - Core

    @objc public var isEnabled: Bool {
        get { defaults.bool(forKey: Key.enabled.rawValue) }
        set { defaults.set(newValue, forKey: Key.enabled.rawValue); notifyChange() }
    }

    @objc public var glossIntensity: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.glossIntensity.rawValue)) }
        set {
            let v = max(0, min(1, newValue))
            defaults.set(Double(v), forKey: Key.glossIntensity.rawValue)
            notifyChange()
        }
    }

    @objc public var lightIntensity: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.lightIntensity.rawValue)) }
        set { defaults.set(Double(max(0, min(1, newValue))), forKey: Key.lightIntensity.rawValue); notifyChange() }
    }

    @objc public var darkIntensity: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.darkIntensity.rawValue)) }
        set { defaults.set(Double(max(0, min(1, newValue))), forKey: Key.darkIntensity.rawValue); notifyChange() }
    }

    @objc public var useCustomTint: Bool {
        get { defaults.bool(forKey: Key.useCustomTint.rawValue) }
        set { defaults.set(newValue, forKey: Key.useCustomTint.rawValue); notifyChange() }
    }

    @objc public var customTint: UIColor? {
        get {
            guard useCustomTint,
                  let hex = defaults.string(forKey: Key.customTintHex.rawValue),
                  !hex.isEmpty else { return nil }
            return UIColor(gg_hex: hex)
        }
        set {
            if let color = newValue {
                defaults.set(color.gg_toHex(), forKey: Key.customTintHex.rawValue)
                defaults.set(true, forKey: Key.useCustomTint.rawValue)
            } else {
                defaults.set("", forKey: Key.customTintHex.rawValue)
                defaults.set(false, forKey: Key.useCustomTint.rawValue)
            }
            notifyChange()
        }
    }

    @objc public var lightweightMode: Bool {
        get { defaults.bool(forKey: Key.lightweightMode.rawValue) }
        set { defaults.set(newValue, forKey: Key.lightweightMode.rawValue); notifyChange() }
    }

    /// 0 = Frosted, 1 = Clear, 2 = Tinted
    @objc public var glassMode: Int {
        get { defaults.integer(forKey: Key.glassMode.rawValue) }
        set { defaults.set(newValue, forKey: Key.glassMode.rawValue); notifyChange() }
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

    @objc public var showGlassButton: Bool {
        get { defaults.bool(forKey: Key.showGlassButton.rawValue) }
        set { defaults.set(newValue, forKey: Key.showGlassButton.rawValue); notifyChange() }
    }

    @objc public var springResponse: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.springResponse.rawValue)) }
        set { defaults.set(Double(newValue), forKey: Key.springResponse.rawValue); notifyChange() }
    }

    @objc public var springDamping: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.springDamping.rawValue)) }
        set { defaults.set(Double(newValue), forKey: Key.springDamping.rawValue); notifyChange() }
    }

    @objc public var debugLogging: Bool {
        get { defaults.bool(forKey: Key.debugLogging.rawValue) }
        set { defaults.set(newValue, forKey: Key.debugLogging.rawValue) }
    }

    @objc public var debugOverlay: Bool {
        get { defaults.bool(forKey: Key.debugOverlay.rawValue) }
        set { defaults.set(newValue, forKey: Key.debugOverlay.rawValue); notifyChange() }
    }

    @objc public var activeProfile: String {
        get { defaults.string(forKey: Key.activeProfile.rawValue) ?? "Default" }
        set { defaults.set(newValue, forKey: Key.activeProfile.rawValue); notifyChange() }
    }

    @objc public var chromaticAberration: Bool {
        get { defaults.bool(forKey: Key.chromaticAberration.rawValue) }
        set { defaults.set(newValue, forKey: Key.chromaticAberration.rawValue); notifyChange() }
    }

    // MARK: - Presets

    @objc public func applyPreset(_ name: String) {
        switch name.lowercased() {
        case "clean":
            glossIntensity = 0.35
            lightIntensity = 0.35
            darkIntensity = 0.28
            lightweightMode = true
            glassMode = 1
            chromaticAberration = false
        case "heavy":
            glossIntensity = 0.75
            lightIntensity = 0.75
            darkIntensity = 0.60
            lightweightMode = false
            glassMode = 0
            chromaticAberration = true
        case "performance":
            glossIntensity = 0.40
            lightIntensity = 0.40
            darkIntensity = 0.30
            lightweightMode = true
            glassMode = 1
            chromaticAberration = false
        default: // Default
            glossIntensity = 0.55
            lightIntensity = 0.55
            darkIntensity = 0.40
            lightweightMode = false
            glassMode = 0
            chromaticAberration = false
        }
        activeProfile = name
        notifyChange()
    }

    // MARK: - Export / Import

    @objc public func exportSettings() -> [String: Any] {
        return defaults.dictionaryRepresentation().filter { key, _ in
            key.hasPrefix("GG_")
        }
    }

    @objc public func importSettings(_ dict: [String: Any]) {
        for (key, value) in dict {
            defaults.set(value, forKey: key)
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
        styleNavigationBar = true
        styleTabBar = true
        styleButtons = true
        styleCards = true
        notifyChange()
    }

    // MARK: - Helpers

    private func notifyChange() {
        NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
        if debugLogging {
            print("[GlossyGlass] Preferences updated – profile: \(activeProfile), intensity: \(glossIntensity)")
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

// MARK: - Color helpers

extension UIColor {
    convenience init?(gg_hex: String) {
        var hex = gg_hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex.removeFirst() }
        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else { return nil }
        let r, g, b, a: CGFloat
        switch hex.count {
        case 6:
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255
            b = CGFloat(rgb & 0x0000FF) / 255
            a = 1
        case 8:
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255
            a = CGFloat(rgb & 0x000000FF) / 255
        default: return nil
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    func gg_toHex() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
}
