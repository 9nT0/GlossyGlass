import UIKit

/// Detects the host app and decides how aggressive glass + injection should be.
@objc public enum GlassHostKind: Int {
    case instagram = 0
    case genericSupported = 1
    case unsupported = 2
}

@objc public class GlassAppSupport: NSObject {

    @objc public static let shared = GlassAppSupport()

    private var didWarnUnsupported = false

    @objc public var bundleId: String {
        Bundle.main.bundleIdentifier ?? ""
    }

    @objc public var appName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? "Unknown"
    }

    @objc public var hostKind: GlassHostKind {
        let id = bundleId.lowercased()
        // Instagram (main + variants)
        if id.contains("instagram") || id == "com.burbn.instagram" {
            return .instagram
        }
        // Known-friendly UIKit apps we try generically
        let friendly = [
            "facebook", "messenger", "twitter", "tweetie", "net.whatsapp",
            "telegram", "discord", "snapchat", "tiktok", "reddit", "youtube",
            "apollo", "chrome", "safari", "apple.mobilesafari"
        ]
        if friendly.contains(where: { id.contains($0) }) {
            return .genericSupported
        }
        // Everything else: still try, but may warn
        return .genericSupported
    }

    @objc public var isInstagram: Bool { hostKind == .instagram }

    /// Call after a failed injection budget on non-IG hosts
    @objc public func warnIfUnsupportedIfNeeded() {
        guard !didWarnUnsupported else { return }
        guard hostKind != .instagram else { return }
        // Only warn if we never attached after many tries
        guard !GlassDiagnostics.shared.isAttached else { return }
        guard GlassDiagnostics.shared.lastScore < 20 else { return }

        didWarnUnsupported = true
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "GlossyGlass",
                message: "“\(self.appName)” may not be fully supported.\nGlass will try a generic mode. Some features may be limited.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                GlassSettingsPresenter.present()
            })
            var top = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?.rootViewController
            while let p = top?.presentedViewController { top = p }
            top?.present(alert, animated: true)
        }
    }

    @objc public func summary() -> String {
        "App: \(appName)\nBundle: \(bundleId)\nKind: \(hostKind == .instagram ? "Instagram" : "Generic")"
    }
}
