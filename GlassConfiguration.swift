import UIKit

@objc public enum GlassStyle: Int, CaseIterable {
    case frosted = 0
    case clear = 1
    case tinted = 2

    public var rawString: String {
        switch self {
        case .frosted: return "Frosted"
        case .clear: return "Clear"
        case .tinted: return "Tinted"
        }
    }

    public static func from(_ string: String) -> GlassStyle {
        switch string.lowercased() {
        case "clear": return .clear
        case "tinted": return .tinted
        default: return .frosted
        }
    }
}

@objc public enum GlassPreset: Int, CaseIterable {
    case clean = 0
    case `default` = 1
    case heavy = 2
    case performance = 3

    public var rawString: String {
        switch self {
        case .clean: return "Clean"
        case .default: return "Default"
        case .heavy: return "Heavy"
        case .performance: return "Performance"
        }
    }

    public static func from(_ string: String) -> GlassPreset {
        switch string.lowercased() {
        case "clean": return .clean
        case "heavy": return .heavy
        case "performance": return .performance
        default: return .default
        }
    }
}

@objc public enum GlassScreen: Int, CaseIterable {
    case unknown = 0
    case feed = 1
    case profile = 2
    case messages = 3
    case settings = 4
    case navigation = 5
}

/// Snapshot of all glass settings used by the renderer
@objc public class GlassConfiguration: NSObject {
    @objc public var isEnabled: Bool = true
    @objc public var style: GlassStyle = .frosted
    @objc public var intensity: CGFloat = 0.72
    @objc public var opacity: CGFloat = 0.85
    @objc public var blurEnabled: Bool = true
    @objc public var vibrancyEnabled: Bool = true
    @objc public var noiseEnabled: Bool = false
    @objc public var lightBloomEnabled: Bool = true
    @objc public var cornerRadius: CGFloat = 24
    @objc public var saturation: CGFloat = 0.65
    @objc public var dimming: CGFloat = 0.30
    @objc public var lightIntensity: CGFloat = 0.55
    @objc public var darkIntensity: CGFloat = 0.45
    @objc public var lightweightMode: Bool = false
    @objc public var customTint: UIColor? = nil
    @objc public var springResponse: CGFloat = 0.28
    @objc public var springDamping: CGFloat = 0.72
    @objc public var hapticsEnabled: Bool = true
    @objc public var edgeHighlightEnabled: Bool = true

    @objc public func effectiveIntensity(isDark: Bool) -> CGFloat {
        let base = isDark ? darkIntensity : lightIntensity
        return max(0, min(1, base * intensity))
    }

    @objc public static func fromPreferences() -> GlassConfiguration {
        let p = GlassPreferences.shared
        let c = GlassConfiguration()
        c.isEnabled = p.isEnabled
        c.style = GlassStyle.from(p.style)
        c.intensity = p.intensity
        c.opacity = p.opacity
        c.blurEnabled = p.blurEnabled
        c.vibrancyEnabled = p.vibrancyEnabled
        c.noiseEnabled = p.noiseEnabled
        c.lightBloomEnabled = p.lightBloomEnabled
        c.cornerRadius = p.cornerRadius
        c.saturation = p.saturation
        c.dimming = p.dimming
        c.lightIntensity = p.lightIntensity
        c.darkIntensity = p.darkIntensity
        c.lightweightMode = p.lightweightMode
        c.customTint = p.customTint
        c.springResponse = p.springResponse
        c.springDamping = p.springDamping
        c.hapticsEnabled = p.hapticsEnabled
        c.edgeHighlightEnabled = p.edgeHighlightEnabled
        return c
    }
}
