import UIKit

/// Public API so other tweaks can control GlossyGlass
@objc public class GlossyGlassAPI: NSObject {

    @objc public static let shared = GlossyGlassAPI()

    private override init() { super.init() }

    // MARK: - Enable / Disable

    @objc public func setEnabled(_ enabled: Bool) {
        GlassPreferences.shared.isEnabled = enabled
    }

    @objc public var isEnabled: Bool {
        GlassPreferences.shared.isEnabled
    }

    // MARK: - Intensity

    @objc public func setLightIntensity(_ value: CGFloat) {
        GlassPreferences.shared.lightIntensity = value
    }

    @objc public func setDarkIntensity(_ value: CGFloat) {
        GlassPreferences.shared.darkIntensity = value
    }

    // MARK: - Mode

    /// 0 = Frosted, 1 = Clear, 2 = Tinted
    @objc public func setGlassMode(_ mode: Int) {
        GlassPreferences.shared.glassMode = mode
    }

    // MARK: - Presets

    @objc public func applyPreset(_ name: String) {
        GlassPreferences.shared.applyPreset(name)
    }

    // MARK: - Elements

    @objc public func setStyleNavigationBar(_ on: Bool) {
        GlassPreferences.shared.styleNavigationBar = on
    }

    @objc public func setStyleTabBar(_ on: Bool) {
        GlassPreferences.shared.styleTabBar = on
    }

    @objc public func setStyleButtons(_ on: Bool) {
        GlassPreferences.shared.styleButtons = on
    }

    @objc public func setShowGlassButton(_ on: Bool) {
        GlassPreferences.shared.showGlassButton = on
    }

    // MARK: - Settings Panel

    @objc public func presentSettings() {
        GlassSettingsPresenter.present()
    }

    // MARK: - Export / Import

    @objc public func exportSettings() -> [String: Any] {
        GlassPreferences.shared.exportSettings()
    }

    @objc public func importSettings(_ dict: [String: Any]) {
        GlassPreferences.shared.importSettings(dict)
    }

    // MARK: - Version

    @objc public var version: String { "2.0.0" }
}
