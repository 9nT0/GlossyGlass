import UIKit
import MachO

@_silgen_name("_dyld_image_count")
private func _gg_dyld_image_count() -> UInt32
@_silgen_name("_dyld_get_image_name")
private func _gg_dyld_get_image_name(_ i: UInt32) -> UnsafePointer<CChar>?

/// Deep Instagram environment scanner — classes, images, windows, responders.
@objc public final class GlassIGScanner: NSObject {

    @objc public static let shared = GlassIGScanner()

    private var lastReport: [String: Any] = [:]

    public func scan() -> [String: Any] {
        var report: [String: Any] = [:]
        report["bundle"] = Bundle.main.bundleIdentifier ?? ""
        report["app"] = GlassAppSupport.shared.appName
        report["isInstagram"] = GlassAppSupport.shared.isInstagram
        report["container"] = GlassAppSupport.shared.isContainerEnvironment
        report["signer"] = GlassAppSupport.shared.signerName
        report["ig_classes"] = detectIGClasses()
        report["ig_images"] = detectIGImages()
        report["windows"] = GlassAppSupport.allWindows().count
        report["nav_bars"] = countClass(UINavigationBar.self)
        report["tab_bars"] = countClass(UITabBar.self)
        report["private"] = GlassPrivateBridge.capabilityReport()
        report["engine"] = GlassLiquidEngine.shared.engineReport()
        report["materials"] = GlassMaterialCatalog.shared.materialCount()
        report["pipeline"] = GlassEffectPipeline.shared.evaluateQuality()
        report["timestamp"] = Date().timeIntervalSince1970
        lastReport = report
        return report
    }

    @objc public func scanJSON() -> String {
        let r = scan()
        guard let data = try? JSONSerialization.data(withJSONObject: r, options: [.prettyPrinted]),
              let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }

    @objc public func lastScanJSON() -> String {
        guard !lastReport.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: lastReport, options: [.prettyPrinted]),
              let s = String(data: data, encoding: .utf8) else { return scanJSON() }
        return s
    }

    private func detectIGClasses() -> [String] {
        let names = [
            "IGViewController", "IGTabBarController", "IGNavigationController",
            "IGMainFeedViewController", "IGProfileViewController", "IGHomeViewController",
            "IGDirectInboxViewController", "IGDirectThreadViewController",
            "IGFeedViewController", "IGStoryViewController", "IGExploreViewController",
            "IGSearchViewController", "IGRootViewController", "IGAppDelegate",
            "IGUserSession", "IGScopedViewController", "IGMainAppSurface",
            "IGTabBar", "IGNavigationBar", "IGHomeTabBarController",
            "IGDSTabBar", "IGCustomTabBar", "IGStoryViewerViewController",
            "IGDirectViewController", "IGDirectThreadMenuController"
        ]
        return names.filter { NSClassFromString($0) != nil }
    }

    private func detectIGImages() -> [String] {
        var out: [String] = []
        let count = _gg_dyld_image_count()
        for i in 0..<count {
            guard let c = _gg_dyld_get_image_name(i) else { continue }
            let path = String(cString: c).lowercased()
            if path.contains("instagram") || path.contains("burbn") || path.contains("igframework")
                || path.contains("fbshared") || path.contains("igformat") {
                out.append(String(cString: c))
                if out.count > 40 { break }
            }
        }
        return out
    }

    private func countClass(_ type: AnyClass) -> Int {
        var n = 0
        for w in GlassAppSupport.allWindows() {
            n += countType(type, in: w, depth: 0)
        }
        return n
    }

    private func countType(_ type: AnyClass, in view: UIView, depth: Int) -> Int {
        guard depth < 18 else { return 0 }
        var n = view.isKind(of: type) ? 1 : 0
        for s in view.subviews { n += countType(type, in: s, depth: depth + 1) }
        return n
    }
}
