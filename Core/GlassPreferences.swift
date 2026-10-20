import UIKit

@objc public final class GlassPreferences: NSObject {
    @objc public static let shared = GlassPreferences()
    private enum K {
        static let enabled = "gg.v5.enabled"
        static let glossy = "gg.v5.glossyMode"
        static let intensity = "gg.v5.intensity"
        static let opacity = "gg.v5.opacity"
        static let tab = "gg.v5.tab"
        static let nav = "gg.v5.nav"
        static let buttons = "gg.v5.buttons"
        static let dms = "gg.v5.dms"
        static let reels = "gg.v5.reels"
        static let profiles = "gg.v5.profiles"
        static let feed = "gg.v5.feed"
        static let search = "gg.v5.search"
        static let context = "gg.v5.context"
        static let anim = "gg.v5.anim"
        static let haptics = "gg.v5.haptics"
        static let safe = "gg.v5.safe"
    }
    private let d = UserDefaults.standard

    @objc public var isEnabled: Bool {
        get { d.object(forKey: K.enabled) as? Bool ?? true }
        set { d.set(newValue, forKey: K.enabled); notify() }
    }

    @objc public var glossyMode: Bool {
        get { d.bool(forKey: K.glossy) }
        set {
            d.set(newValue, forKey: K.glossy)
            d.synchronize()
            notify()
            DispatchQueue.main.async {
                GlassChrome.shared.apply(reason: "glossyToggle")
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
        get { (d.object(forKey: K.intensity) as? CGFloat) ?? 0.92 }
        set { d.set(newValue, forKey: K.intensity); notify() }
    }
    @objc public var opacity: CGFloat {
        get { (d.object(forKey: K.opacity) as? CGFloat) ?? 0.96 }
        set { d.set(newValue, forKey: K.opacity); notify() }
    }
    @objc public var styleTabBar: Bool {
        get { d.object(forKey: K.tab) as? Bool ?? true }
        set { d.set(newValue, forKey: K.tab); notify() }
    }
    @objc public var styleNavBar: Bool {
        get { d.object(forKey: K.nav) as? Bool ?? true }
        set { d.set(newValue, forKey: K.nav); notify() }
    }
    @objc public var styleButtons: Bool {
        get { d.object(forKey: K.buttons) as? Bool ?? true }
        set { d.set(newValue, forKey: K.buttons); notify() }
    }
    @objc public var styleDMs: Bool {
        get { d.object(forKey: K.dms) as? Bool ?? true }
        set { d.set(newValue, forKey: K.dms); notify() }
    }
    @objc public var styleReels: Bool {
        get { d.object(forKey: K.reels) as? Bool ?? true }
        set { d.set(newValue, forKey: K.reels); notify() }
    }
    @objc public var styleProfiles: Bool {
        get { d.object(forKey: K.profiles) as? Bool ?? true }
        set { d.set(newValue, forKey: K.profiles); notify() }
    }
    @objc public var styleFeed: Bool {
        get { d.object(forKey: K.feed) as? Bool ?? true }
        set { d.set(newValue, forKey: K.feed); notify() }
    }
    @objc public var styleSearch: Bool {
        get { d.object(forKey: K.search) as? Bool ?? true }
        set { d.set(newValue, forKey: K.search); notify() }
    }
    @objc public var styleContext: Bool {
        get { d.object(forKey: K.context) as? Bool ?? true }
        set { d.set(newValue, forKey: K.context); notify() }
    }
    @objc public var animations: Bool {
        get { d.object(forKey: K.anim) as? Bool ?? true }
        set { d.set(newValue, forKey: K.anim) }
    }
    @objc public var haptics: Bool {
        get { d.object(forKey: K.haptics) as? Bool ?? true }
        set { d.set(newValue, forKey: K.haptics) }
    }
    @objc public var safeMode: Bool {
        get { d.bool(forKey: K.safe) }
        set { d.set(newValue, forKey: K.safe); notify() }
    }

    private func notify() {
        NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
    }

    @objc public func resetToDefaults() {
        isEnabled = true; glossyMode = false
        intensity = 0.92; opacity = 0.96
        styleTabBar = true; styleNavBar = true; styleButtons = true
        styleDMs = true; styleReels = true; styleProfiles = true
        styleFeed = true; styleSearch = true; styleContext = true
        animations = true; haptics = true; safeMode = false
    }
}

extension Notification.Name {
    static let glassPreferencesDidChange = Notification.Name("GlassPreferencesDidChange")
}
