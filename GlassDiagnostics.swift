import UIKit

@objc public class GlassDiagnostics: NSObject {

    @objc public static let shared = GlassDiagnostics()

    @objc public private(set) var lastScore: Int = 0
    @objc public private(set) var lastHostClass: String = "none"
    @objc public private(set) var candidateCount: Int = 0
    @objc public private(set) var isAttached: Bool = false
    @objc public private(set) var lastInjectionNote: String = ""

    @objc public var hostAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    @objc public var glassVersion: String { "3.6.1" }

    @objc public var iosVersion: String { UIDevice.current.systemVersion }
    @objc public var deviceModel: String { UIDevice.current.model }

    @objc public func recordInjection(score: Int, host: String, candidates: Int, attached: Bool, note: String) {
        lastScore = score
        lastHostClass = host
        candidateCount = candidates
        isAttached = attached
        lastInjectionNote = note
        GlassPreferences.shared.log("Diag: score=\(score) host=\(host) cands=\(candidates) attached=\(attached) — \(note)")
    }

    @objc public func summary() -> String {
        let p = GlassPreferences.shared
        return """
        GlossyGlass Diagnostics v3.6.1
        ----------------------------
        Glass: \(glassVersion)
        iOS: \(iosVersion)
        Device: \(deviceModel)
        Host app: \(hostAppVersion)

        Enabled: \(p.isEnabled)
        Safe mode: \(p.safeMode)
        Style: \(p.style)
        Intensity: \(String(format: "%.2f", p.intensity))
        Opacity: \(String(format: "%.2f", p.opacity))
        Blur: \(p.blurEnabled)  Vibrancy: \(p.vibrancyEnabled)
        Noise: \(p.noiseEnabled)  Bloom: \(p.lightBloomEnabled)
        Edge: \(p.edgeHighlightEnabled)
        Lightweight: \(p.lightweightMode)

        Attached: \(isAttached)
        Last score: \(lastScore)
        Host: \(lastHostClass)
        Candidates: \(candidateCount)
        Note: \(lastInjectionNote)
        """
    }

    @objc public func present(from presenter: UIViewController? = nil) {
        let alert = UIAlertController(title: "Glass Diagnostics", message: summary(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
            UIPasteboard.general.string = self.summary()
        })
        alert.addAction(UIAlertAction(title: "Re-detect UI", style: .default) { _ in
            GlassInjector.forceRedetect()
        })
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))

        let top = presenter ?? GlassAppSupport.topViewController()
        top?.present(alert, animated: true)
    }
}
