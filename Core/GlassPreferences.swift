//
//  GlassPreferences.swift
//  GlossyGlass v5
//
//  Single source of truth. No scattered UserDefaults keys.
//

import UIKit

@objc public final class GlassPreferences: NSObject {

    @objc public static let shared = GlassPreferences()

    // MARK: - Keys
    private enum Key {
        static let enabled          = "gg.v5.enabled"
        static let glossyMode       = "gg.v5.glossyMode"
        static let intensity        = "gg.v5.intensity"
        static let opacity          = "gg.v5.opacity"
        static let styleTabBar      = "gg.v5.styleTabBar"
        static let styleNavBar      = "gg.v5.styleNavBar"
        static let styleButtons     = "gg.v5.styleButtons"
        static let haptics          = "gg.v5.haptics"
        static let safeMode         = "gg.v5.safeMode"
        static let forceShowButton  = "gg.v5.forceShowButton"
    }

    private let defaults = UserDefaults.standard

    // MARK: - Public properties

    @objc public var isEnabled: Bool {
        get { defaults.object(forKey: Key.enabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.enabled); notify() }
    }

    /// The main toggle the user asked for.
    /// ON  = full iOS-26 glossy look + new panel + remade icons
    /// OFF = clean base liquid-glass
    @objc public var glossyMode: Bool {
        get { defaults.bool(forKey: Key.glossyMode) }
        set {
            defaults.set(newValue, forKey: Key.glossyMode)
            notify()
            // Switch panel immediately
            if newValue {
                GlassPanelGlossy.shared.present()
            } else {
                GlassPanelGlossy.shared.dismiss()
                GlassPanel.shared.present()
            }
        }
    }

    @objc public var intensity: CGFloat {
        get {
            let v = defaults.object(forKey: Key.intensity) as? CGFloat
            return v ?? 0.85
        }
        set { defaults.set(newValue, forKey: Key.intensity); notify() }
    }

    @objc public var opacity: CGFloat {
        get {
            let v = defaults.object(forKey: Key.opacity) as? CGFloat
            return v ?? 0.92
        }
        set { defaults.set(newValue, forKey: Key.opacity); notify() }
    }

    @objc public var styleTabBar: Bool {
        get { defaults.object(forKey: Key.styleTabBar) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.styleTabBar); notify() }
    }

    @objc public var styleNavBar: Bool {
        get { defaults.object(forKey: Key.styleNavBar) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.styleNavBar); notify() }
    }

    @objc public var styleButtons: Bool {
        get { defaults.object(forKey: Key.styleButtons) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.styleButtons); notify() }
    }

    @objc public var haptics: Bool {
        get { defaults.object(forKey: Key.haptics) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.haptics) }
    }

    @objc public var safeMode: Bool {
        get { defaults.bool(forKey: Key.safeMode) }
        set { defaults.set(newValue, forKey: Key.safeMode); notify() }
    }

    @objc public var forceShowButton: Bool {
        get { defaults.bool(forKey: Key.forceShowButton) }
        set { defaults.set(newValue, forKey: Key.forceShowButton); notify() }
    }

    // MARK: - Notify

    private func notify() {
        NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
    }

    // MARK: - Helpers

    @objc public func resetToDefaults() {
        isEnabled = true
        glossyMode = false
        intensity = 0.85
        opacity = 0.92
        styleTabBar = true
        styleNavBar = true
        styleButtons = true
        haptics = true
        safeMode = false
        forceShowButton = false
    }
}

extension Notification.Name {
    static let glassPreferencesDidChange = Notification.Name("GlassPreferencesDidChange")
}
