import UIKit
import Foundation

/// Central preferences for GlossyGlass.
/// Works with UserDefaults (easy for sideloaded dylibs) and is designed
/// so a Preference Bundle can later write to the same keys.
@objc public class GlassPreferences: NSObject {

    // MARK: - Keys (shared with potential Preference Bundle)

    private static let suiteName = "com.glossyglass.preferences"

    private enum Key: String {
        case enabled              = "GG_Enabled"
        case glossIntensity       = "GG_GlossIntensity"
        case useCustomTint        = "GG_UseCustomTint"
        case customTintHex        = "GG_CustomTintHex"
        case lightweightMode      = "GG_LightweightMode"
        case styleNavigationBar   = "GG_StyleNavigationBar"
        case styleTabBar          = "GG_StyleTabBar"
        case styleButtons         = "GG_StyleButtons"
        case styleCards           = "GG_StyleCards"
        case debugLogging         = "GG_DebugLogging"
    }

    // MARK: - Shared instance

    @objc public static let shared = GlassPreferences()

    private let defaults: UserDefaults

    private override init() {
        // Prefer a suite so it can be shared cleanly
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
            Key.glossIntensity.rawValue     : 0.50,
            Key.useCustomTint.rawValue      : false,
            Key.customTintHex.rawValue      : "",
            Key.lightweightMode.rawValue    : false,
            Key.styleNavigationBar.rawValue : true,
            Key.styleTabBar.rawValue        : true,
            Key.styleButtons.rawValue       : true,
            Key.styleCards.rawValue         : true,
            Key.debugLogging.rawValue       : false
        ])
    }

    // MARK: - Public Settings

    @objc public var isEnabled: Bool {
        get { defaults.bool(forKey: Key.enabled.rawValue) }
        set {
            defaults.set(newValue, forKey: Key.enabled.rawValue)
            notifyChange()
        }
    }

    @objc public var glossIntensity: CGFloat {
        get {
            let v = defaults.double(forKey: Key.glossIntensity.rawValue)
            return CGFloat(v)
        }
        set {
            let clamped = max(0.0, min(1.0, newValue))
            defaults.set(Double(clamped), forKey: Key.glossIntensity.rawValue)
            notifyChange()
        }
    }

    @objc public var useCustomTint: Bool {
        get { defaults.bool(forKey: Key.useCustomTint.rawValue) }
        set {
            defaults.set(newValue, forKey: Key.useCustomTint.rawValue)
            notifyChange()
        }
    }

    @objc public var customTint: UIColor? {
        get {
            guard useCustomTint,
                  let hex = defaults.string(forKey: Key.customTintHex.rawValue),
                  !hex.isEmpty else { return nil }
            return UIColor(hex: hex)
        }
        set {
            if let color = newValue {
                defaults.set(color.toHexString(), forKey: Key.customTintHex.rawValue)
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
        set {
            defaults.set(newValue, forKey: Key.lightweightMode.rawValue)
            notifyChange()
        }
    }

    @objc public var styleNavigationBar: Bool {
        get { defaults.bool(forKey: Key.styleNavigationBar.rawValue) }
        set {
            defaults.set(newValue, forKey: Key.styleNavigationBar.rawValue)
            notifyChange()
        }
    }

    @objc public var styleTabBar: Bool {
        get { defaults.bool(forKey: Key.styleTabBar.rawValue) }
        set {
            defaults.set(newValue, forKey: Key.styleTabBar.rawValue)
            notifyChange()
        }
    }

    @objc public var styleButtons: Bool {
        get { defaults.bool(forKey: Key.styleButtons.rawValue) }
        set {
            defaults.set(newValue, forKey: Key.styleButtons.rawValue)
            notifyChange()
        }
    }

    @objc public var styleCards: Bool {
        get { defaults.bool(forKey: Key.styleCards.rawValue) }
        set {
            defaults.set(newValue, forKey: Key.styleCards.rawValue)
            notifyChange()
        }
    }

    @objc public var debugLogging: Bool {
        get { defaults.bool(forKey: Key.debugLogging.rawValue) }
        set { defaults.set(newValue, forKey: Key.debugLogging.rawValue) }
    }

    // MARK: - Helpers

    @objc public func resetToDefaults() {
        let domain = defaults.dictionaryRepresentation().keys
        domain.forEach { defaults.removeObject(forKey: $0) }
        registerDefaults()
        notifyChange()
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
        if debugLogging {
            print("[GlossyGlass] Preferences updated – enabled: \(isEnabled), gloss: \(glossIntensity)")
        }
    }

    @objc public func log(_ message: String) {
        guard debugLogging else { return }
        print("[GlossyGlass] \(message)")
    }
}

// MARK: - Notification

public extension Notification.Name {
    static let glassPreferencesDidChange = Notification.Name("GlassPreferencesDidChange")
}

// MARK: - UIColor Hex helpers

private extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") { hexSanitized.removeFirst() }

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b, a: CGFloat
        switch hexSanitized.count {
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

    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255) << 0
        return String(format: "#%06x", rgb)
    }
}
