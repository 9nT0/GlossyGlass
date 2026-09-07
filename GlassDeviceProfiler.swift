import UIKit

/// Detects device capability on first launch and applies a safe preset.
/// User can change anything afterward — this only runs once.
@objc public class GlassDeviceProfiler: NSObject {

    private static let firstLaunchKey = "GG_FirstLaunchProfileApplied"

    public enum Tier: String {
        case low        // older / less RAM → Performance
        case medium     // mid devices → Default / Clean
        case high       // recent flagships → Default (full effects ok)
    }

    @objc public static func applyIfNeeded() {
        let defaults = UserDefaults(suiteName: "com.glossyglass.preferences") ?? .standard
        if defaults.bool(forKey: firstLaunchKey) { return }

        let tier = detectTier()
        let prefs = GlassPreferences.shared

        switch tier {
        case .low:
            prefs.applyPreset("Performance")
            prefs.lightweightMode = true
            prefs.noiseEnabled = false
            prefs.lightBloomEnabled = false
            prefs.vibrancyEnabled = false
            prefs.edgeHighlightEnabled = false
            prefs.blurEnabled = true
            prefs.log("DeviceProfiler: LOW tier → Performance preset")
        case .medium:
            prefs.applyPreset("Clean")
            prefs.lightweightMode = true
            prefs.noiseEnabled = false
            prefs.lightBloomEnabled = true
            prefs.edgeHighlightEnabled = true
            prefs.log("DeviceProfiler: MEDIUM tier → Clean preset")
        case .high:
            prefs.applyPreset("Default")
            prefs.lightweightMode = false
            prefs.log("DeviceProfiler: HIGH tier → Default preset")
        }

        defaults.set(true, forKey: firstLaunchKey)
        defaults.synchronize()
    }

    public static func detectTier() -> Tier {
        // Physical memory (bytes)
        let mem = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0 // GiB
        let cores = ProcessInfo.processInfo.processorCount
        let ver = (UIDevice.current.systemVersion as NSString).floatValue

        // Model heuristic via utsname
        var systemInfo = utsname()
        uname(&systemInfo)
        let model = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "unknown"
            }
        }

        // Very rough: iPhone10,* and below or low RAM → low
        let isOldModel = model.contains("iPhone8") || model.contains("iPhone9") ||
            model.contains("iPhone10") || model.contains("iPad5") || model.contains("iPad6")

        if mem < 3.0 || cores <= 4 || isOldModel {
            return .low
        }
        if mem < 5.5 || cores <= 6 || ver < 17.5 {
            return .medium
        }
        return .high
    }

    @objc public static func currentTierName() -> String {
        detectTier().rawValue
    }
}
