import UIKit

/// GlossyGlass Public API v36 — full control surface for other tweaks.
@objc public class GlossyGlassAPI: NSObject {

    @objc public static let shared = GlossyGlassAPI()
    @objc public static let apiVersion: Int = 40
    @objc public static let apiVersionString: String = "4.0.2"

    // MARK: - Core enable

    @objc public func setEnabled(_ enabled: Bool) {
        GlassPreferences.shared.isEnabled = enabled
        if enabled { GlassPreferences.shared.safeMode = false }
        post()
    }

    @objc public func isEnabled() -> Bool { GlassPreferences.shared.isEnabled }

    @objc public func toggleEnabled() {
        setEnabled(!isEnabled())
    }

    // MARK: - Safe mode

    @objc public func enterSafeMode() {
        GlassPreferences.shared.safeMode = true
        GlassInjector.forceRedetect()
        post()
    }

    @objc public func exitSafeMode() {
        GlassPreferences.shared.safeMode = false
        GlassPreferences.shared.crashCount = 0
        GlassInjector.forceRedetect()
        post()
    }

    @objc public func isSafeMode() -> Bool { GlassPreferences.shared.safeMode }

    // MARK: - Presets & style

    @objc public func applyPreset(_ name: String) { GlassPreferences.shared.applyPreset(name); post() }
    @objc public func applyPresetEnum(_ preset: GlassPreset) { applyPreset(preset.rawString) }
    @objc public func currentPreset() -> String { GlassPreferences.shared.preset }

    @objc public func setStyle(_ name: String) { GlassPreferences.shared.style = name; post() }
    @objc public func setStyleEnum(_ style: GlassStyle) { setStyle(style.rawString) }
    @objc public func currentStyle() -> String { GlassPreferences.shared.style }

    @objc public func applyQuickTheme(_ theme: String) {
        switch theme.lowercased() {
        case "midnight":
            setStyle("Frosted"); setDarkIntensity(0.75); setLightIntensity(0.40)
            setOpacity(0.90); setBloomEnabled(true); setEdgeHighlightEnabled(true); setNoiseEnabled(false)
        case "crystal":
            setStyle("Clear"); setIntensity(0.45); setOpacity(0.70)
            setBloomEnabled(false); setEdgeHighlightEnabled(true); setNoiseEnabled(false)
        case "smoke":
            setStyle("Tinted"); setIntensity(0.80); setOpacity(0.95)
            setBloomEnabled(true); setNoiseEnabled(true); setEdgeHighlightEnabled(true)
        case "minimal":
            applyPreset("Performance"); setEdgeHighlightEnabled(false); setBloomEnabled(false)
        default:
            applyPreset("Default")
        }
        post()
    }

    // MARK: - Intensities & materials

    @objc public func setIntensity(_ value: CGFloat) { GlassPreferences.shared.intensity = value }
    @objc public func setLightIntensity(_ value: CGFloat) { GlassPreferences.shared.lightIntensity = value }
    @objc public func setDarkIntensity(_ value: CGFloat) { GlassPreferences.shared.darkIntensity = value }
    @objc public func setOpacity(_ value: CGFloat) { GlassPreferences.shared.opacity = value }
    @objc public func setCornerRadius(_ value: CGFloat) { GlassPreferences.shared.cornerRadius = value }
    @objc public func setSaturation(_ value: CGFloat) { GlassPreferences.shared.saturation = value }
    @objc public func setDimming(_ value: CGFloat) { GlassPreferences.shared.dimming = value }

    @objc public func setBlurEnabled(_ on: Bool) { GlassPreferences.shared.blurEnabled = on }
    @objc public func setVibrancyEnabled(_ on: Bool) { GlassPreferences.shared.vibrancyEnabled = on }
    @objc public func setNoiseEnabled(_ on: Bool) { GlassPreferences.shared.noiseEnabled = on }
    @objc public func setBloomEnabled(_ on: Bool) { GlassPreferences.shared.lightBloomEnabled = on }
    @objc public func setEdgeHighlightEnabled(_ on: Bool) { GlassPreferences.shared.edgeHighlightEnabled = on }
    @objc public func setLightweightMode(_ on: Bool) { GlassPreferences.shared.lightweightMode = on }
    @objc public func setHapticsEnabled(_ on: Bool) { GlassPreferences.shared.hapticsEnabled = on }

    @objc public func setSpringResponse(_ value: CGFloat) { GlassPreferences.shared.springResponse = value }
    @objc public func setSpringDamping(_ value: CGFloat) { GlassPreferences.shared.springDamping = value }

    // MARK: - Chrome toggles

    @objc public func setStyleNavigationBar(_ on: Bool) { GlassPreferences.shared.styleNavigationBar = on; GlassStyleApplicator.applyAll() }
    @objc public func setStyleTabBar(_ on: Bool) { GlassPreferences.shared.styleTabBar = on; GlassStyleApplicator.applyAll() }
    @objc public func setStyleButtons(_ on: Bool) { GlassPreferences.shared.styleButtons = on; GlassStyleApplicator.applyAll() }
    @objc public func setStyleCards(_ on: Bool) { GlassPreferences.shared.styleCards = on; GlassStyleApplicator.applyAll() }

    @objc public func reapplyChromeStyles() { GlassStyleApplicator.applyAll() }

    // MARK: - Button placement

    @objc public func setHideGlassButton(_ on: Bool) {
        GlassPreferences.shared.hideGlassButton = on
        GlassInjector.forceRedetect()
    }

    @objc public func setForceShowGlassButton(_ on: Bool) {
        GlassPreferences.shared.forceShowGlassButton = on
        GlassInjector.forceRedetect()
    }

    @objc public func isForceShowGlassButton() -> Bool { GlassPreferences.shared.forceShowGlassButton }

    // MARK: - Focus / live tint

    @objc public func setFocusMode(_ on: Bool) {
        GlassLiveState.shared.focusMode = on
        NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
        post()
    }

    @objc public func isFocusMode() -> Bool { GlassLiveState.shared.focusMode }

    @objc public func setLiveTint(_ color: UIColor?) {
        GlassLiveState.shared.liveTint = color
        NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
    }

    @objc public func clearLiveTint() { setLiveTint(nil) }

    // MARK: - Configuration snapshot

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
        post()
    }

    @objc public func configuration() -> GlassConfiguration {
        GlassConfiguration.fromPreferences()
    }

    // MARK: - Screen profiles

    @objc public func setAutoApplyScreenProfiles(_ on: Bool) {
        GlassPreferences.shared.autoApplyScreenProfiles = on
    }

    @objc public func setScreenProfile(_ name: String, forScreen screen: GlassScreen) {
        GlassPreferences.shared.setProfileName(name, for: screen)
    }

    @objc public func screenProfile(forScreen screen: GlassScreen) -> String {
        GlassPreferences.shared.profileName(for: screen)
    }

    @objc public func applyScreenProfile(_ screen: GlassScreen) {
        let name = GlassPreferences.shared.profileName(for: screen)
        if name == "Off" { return }
        applyPreset(name)
    }

    // MARK: - Injection control

    @objc public func forceRedetect() { GlassInjector.forceRedetect() }
    @objc public func resetInjectionState() { GlassInjector.resetInjectionState() }
    @objc public func startInjection() { GlassInjector.start() }

    // MARK: - UI

    @objc public func presentSettings() { GlassSettingsPresenter.present() }

    @objc public func presentWelcome() { GlassWelcome.present(force: true) }

    @objc public func applyLiquidGlassLook() { GlassThemeEngine.shared.applyLiquidDefault() }

    @objc public func applyLiquidHeavyLook() { GlassThemeEngine.shared.applyLiquidHeavy() }
    

    // MARK: - v4.0.2 Expanded API

    @objc public func privateCapabilityReport() -> String {
        GlassPrivateBridge.capabilityReport()
    }

    @objc public func liquidEngineReport() -> String {
        GlassLiquidEngine.shared.engineReport()
    }

    @objc public func runIGScan() -> String {
        GlassIGScanner.shared.scanJSON()
    }

    @objc public func materialCatalogCount() -> Int {
        GlassMaterialCatalog.shared.materialCount()
    }

    @objc public func materialCatalogJSON() -> String {
        GlassMaterialCatalog.shared.catalogJSON()
    }

    @objc public func applyMaterialID(_ materialId: String) {
        GlassMaterialCatalog.shared.applyMaterial(id: materialId)
    }

    @objc public func effectPipelineQualityJSON() -> String {
        let q = GlassEffectPipeline.shared.evaluateQuality()
        guard let data = try? JSONSerialization.data(withJSONObject: q, options: []),
              let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }

    @objc public func hasNativeUIGlass() -> Bool {
        GlassPrivateBridge.hasUIGlassEffect
    }

    @objc public func presentDiagnostics() { GlassDiagnostics.shared.present() }

    // MARK: - Persistence

    @objc public func exportSettingsJSON() -> String? { GlassPreferences.shared.exportSettingsJSON() }
    @objc public func importSettingsJSON(_ json: String) -> Bool {
        let ok = GlassPreferences.shared.importSettingsJSON(json)
        if ok { post() }
        return ok
    }

    @objc public func resetStylesOnly() { GlassPreferences.shared.resetStylesOnly(); post() }
    @objc public func resetAll() { GlassPreferences.shared.resetToDefaults(); post() }

    // MARK: - Host / diagnostics

    @objc public func hostAppSummary() -> String { GlassAppSupport.shared.summary() }
    @objc public func isInstagramHost() -> Bool { GlassAppSupport.shared.isInstagram }

    // MARK: - Signing / container

    @objc public func isContainerEnvironment() -> Bool { GlassAppSupport.shared.isContainerEnvironment }

    @objc public func refreshHostDetection() { GlassAppSupport.shared.refreshDetection() }

    @objc public func signerName() -> String { GlassAppSupport.shared.signerName }

    @objc public func signerKindRaw() -> Int { GlassAppSupport.shared.signerKind.rawValue }

    @objc public func isLiveContainer() -> Bool {
        GlassAppSupport.shared.signerKind == .liveContainer
    }

    @objc public func isKnownSigner() -> Bool {
        GlassAppSupport.shared.signerKind != .unknown
    }

    /// Soft guidance string for UI / other tweaks
    @objc public func containerCompatibilityNote() -> String {
        let s = GlassAppSupport.shared
        if s.isInstagram && s.isContainerEnvironment {
            return "Instagram detected inside \(s.signerName). Force Show recommended if the bar is missing."
        }
        if s.isContainerEnvironment {
            return "Container: \(s.signerName). Guest detection may lag — open the app fully."
        }
        if s.isInstagram {
            return "Native Instagram host."
        }
        return "Generic host (\(s.signerName))."
    }

    /// Enable container-friendly defaults (force show + denser behavior flags)
    @objc public func applyContainerFriendlyDefaults() {
        let p = GlassPreferences.shared
        p.forceShowGlassButton = true
        p.hideGlassButton = false
        p.lightweightMode = (GlassDeviceProfiler.currentTierName() == "low")
        GlassInjector.forceRedetect()
        post()
    }




    @objc public func hostBundleId() -> String { GlassAppSupport.shared.bundleId }
    @objc public func deviceTier() -> String { GlassDeviceProfiler.currentTierName() }
    @objc public func diagnosticsSummary() -> String { GlassDiagnostics.shared.summary() }

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
            "container": GlassAppSupport.shared.isContainerEnvironment,
            "attached": d.isAttached,
            "score": d.lastScore,
            "hostClass": d.lastHostClass,
            "enabled": p.isEnabled,
            "safeMode": p.safeMode,
            "forceShow": p.forceShowGlassButton,
            "style": p.style,
            "intensity": p.intensity,
            "opacity": p.opacity,
            "deviceTier": GlassDeviceProfiler.currentTierName()
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
              let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }

    @objc public var stateChangeNotificationName: String {
        Notification.Name.glassAPIStateDidChange.rawValue
    }

    private func post() {
        NotificationCenter.default.post(name: .glassAPIStateDidChange, object: nil)
    }
}

@objc public class GlassLiveState: NSObject {
    @objc public static let shared = GlassLiveState()
    @objc public var liveTint: UIColor? = nil
    @objc public var focusMode: Bool = false
}

public extension Notification.Name {
    static let glassAPIStateDidChange = Notification.Name("GlassAPIStateDidChange")
}
