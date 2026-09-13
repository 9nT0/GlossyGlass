import UIKit

@objc public class GlassHealthChecker: NSObject {
    @objc public static let shared = GlassHealthChecker()

    @objc public private(set) var lastReport: [String: String] = [:]

    @objc public func runAll() -> [String: String] {
        var r: [String: String] = [:]
        r["prefs"] = GlassPreferences.shared.isEnabled ? "ok" : "disabled"
        r["safeMode"] = GlassPreferences.shared.safeMode ? "on" : "off"
        r["instagram"] = GlassAppSupport.shared.isInstagram ? "yes" : "no"
        r["container"] = GlassAppSupport.shared.isContainerEnvironment ? "yes" : "no"
        r["windows"] = "\(GlassAppSupport.allWindows().count)"
        r["uiReady"] = GlassReadyGate.shared.isUIReady() ? "yes" : "no"
        r["attached"] = GlassDiagnostics.shared.isAttached ? "yes" : "no"
        r["score"] = "\(GlassDiagnostics.shared.lastScore)"
        r["nativeGlass"] = GlassNativeBridge.isNativeGlassAvailable ? "yes" : "no"
        r["forceShow"] = GlassPreferences.shared.forceShowGlassButton ? "on" : "off"
        lastReport = r
        GlassPreferences.shared.log("Health: \(r)")
        return r
    }

    @objc public func summaryLine() -> String {
        let r = runAll()
        return r.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " ")
    }
}
