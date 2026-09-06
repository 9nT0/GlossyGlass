import UIKit

/// Runtime diagnostics for debugging injection and renderer state
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

    @objc public var glassVersion: String { "3.0.0" }

    @objc public var iosVersion: String {
        UIDevice.current.systemVersion
    }

    @objc public var deviceModel: String {
        UIDevice.current.model
    }

    @objc public func recordInjection(score: Int, host: String, candidates: Int, attached: Bool, note: String) {
        lastScore = score
        lastHostClass = host
        candidateCount = candidates
        isAttached = attached
        lastInjectionNote = note
        GlassPreferences.shared.log("Diagnostics: score=\(score) host=\(host) candidates=\(candidates) attached=\(attached) — \(note)")
    }

    @objc public func summary() -> String {
        """
        GlossyGlass Diagnostics
        -----------------------
        Glass: \(glassVersion)
        iOS: \(iosVersion)
        Device: \(deviceModel)
        Host app: \(hostAppVersion)
        Safe mode: \(GlassPreferences.shared.safeMode)
        Attached: \(isAttached)
        Last score: \(lastScore)
        Host class: \(lastHostClass)
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

        let root = presenter ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController

        var top = root
        while let p = top?.presentedViewController { top = p }
        top?.present(alert, animated: true)
    }
}
