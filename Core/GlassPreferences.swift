import UIKit

@objc public final class GlassPreferences: NSObject {
    @objc public static let shared = GlassPreferences()

    private enum Key {
        static let enabled = "gg.v5.enabled"
        static let glossyMode = "gg.v5.glossyMode"
        static let intensity = "gg.v5.intensity"
        static let opacity = "gg.v5.opacity"
        static let styleTabBar = "gg.v5.styleTabBar"
        static let styleNavBar = "gg.v5.styleNavBar"
        static let styleButtons = "gg.v5.styleButtons"
        static let styleDMs = "gg.v5.styleDMs"
        static let styleReels = "gg.v5.styleReels"
        static let styleProfiles = "gg.v5.styleProfiles"
        static let animations = "gg.v5.animations"
        static let haptics = "gg.v5.haptics"
        static let safeMode = "gg.v5.safeMode"
    }

    private let d = UserDefaults.standard

    @objc public var isEnabled: Bool {
        get { d.object(forKey: Key.enabled) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.enabled); notify() }
    }

    @objc public var glossyMode: Bool {
        get { d.bool(forKey: Key.glossyMode) }
        set {
            d.set(newValue, forKey: Key.glossyMode)
            notify()
            DispatchQueue.main.async {
                if newValue {
                    GlassPanel.shared.dismiss()
                    GlassPanelGlossy.shared.present()
                } else {
                    GlassPanelGlossy.shared.dismiss()
                    GlassPanel.shared.present()
                }
            }
        }
    }

    @objc public var intensity: CGFloat {
        get { (d.object(forKey: Key.intensity) as? CGFloat) ?? 0.90 }
        set { d.set(newValue, forKey: Key.intensity); notify() }
    }

    @objc public var opacity: CGFloat {
        get { (d.object(forKey: Key.opacity) as? CGFloat) ?? 0.94 }
        set { d.set(newValue, forKey: Key.opacity); notify() }
    }

    @objc public var styleTabBar: Bool {
        get { d.object(forKey: Key.styleTabBar) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.styleTabBar); notify() }
    }

    @objc public var styleNavBar: Bool {
        get { d.object(forKey: Key.styleNavBar) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.styleNavBar); notify() }
    }

    @objc public var styleButtons: Bool {
        get { d.object(forKey: Key.styleButtons) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.styleButtons); notify() }
    }

    @objc public var styleDMs: Bool {
        get { d.object(forKey: Key.styleDMs) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.styleDMs); notify() }
    }

    @objc public var styleReels: Bool {
        get { d.object(forKey: Key.styleReels) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.styleReels); notify() }
    }

    @objc public var styleProfiles: Bool {
        get { d.object(forKey: Key.styleProfiles) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.styleProfiles); notify() }
    }

    @objc public var animations: Bool {
        get { d.object(forKey: Key.animations) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.animations) }
    }

    @objc public var haptics: Bool {
        get { d.object(forKey: Key.haptics) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.haptics) }
    }

    @objc public var safeMode: Bool {
        get { d.bool(forKey: Key.safeMode) }
        set { d.set(newValue, forKey: Key.safeMode); notify() }
    }

    private func notify() {
        NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
    }

    @objc public func resetToDefaults() {
        isEnabled = true
        glossyMode = false
        intensity = 0.90
        opacity = 0.94
        styleTabBar = true
        styleNavBar = true
        styleButtons = true
        styleDMs = true
        styleReels = true
        styleProfiles = true
        animations = true
        haptics = true
        safeMode = false
    }
}

extension Notification.Name {
    static let glassPreferencesDidChange = Notification.Name("GlassPreferencesDidChange")
}
