import UIKit

@objc public class GlossyGlassAPI: NSObject {

    @objc public static let shared = GlossyGlassAPI()
    @objc public static let apiVersion: Int = 3

    @objc public func setEnabled(_ enabled: Bool) {
        GlassPreferences.shared.isEnabled = enabled
        if enabled { GlassPreferences.shared.safeMode = false }
    }

    @objc public func isEnabled() -> Bool {
        GlassPreferences.shared.isEnabled
    }

    @objc public func applyPreset(_ name: String) {
        GlassPreferences.shared.applyPreset(name)
    }

    @objc public func applyPresetEnum(_ preset: GlassPreset) {
        GlassPreferences.shared.applyPreset(preset.rawString)
    }

    @objc public func presentSettings() {
        GlassSettingsPresenter.present()
    }

    @objc public func presentDiagnostics() {
        GlassDiagnostics.shared.present()
    }

    @objc public func exportSettingsJSON() -> String? {
        GlassPreferences.shared.exportSettingsJSON()
    }

    @objc public func importSettingsJSON(_ json: String) -> Bool {
        GlassPreferences.shared.importSettingsJSON(json)
    }

    @objc public func forceRedetect() {
        GlassInjector.forceRedetect()
    }

    /// Safe mode only blocks injection — visual glass can stay on
    @objc public func enterSafeMode() {
        GlassPreferences.shared.safeMode = true
        GlassInjector.forceRedetect()
    }

    @objc public func exitSafeMode() {
        GlassPreferences.shared.safeMode = false
        GlassPreferences.shared.crashCount = 0
        GlassInjector.forceRedetect()
    }

    @objc public func configuration() -> GlassConfiguration {
        GlassConfiguration.fromPreferences()
    }
}
