import UIKit
import Darwin
import MachO

@_silgen_name("_dyld_image_count")
private func _gg_dyld_image_count() -> UInt32
@_silgen_name("_dyld_get_image_name")
private func _gg_dyld_get_image_name(_ image_index: UInt32) -> UnsafePointer<CChar>?

@objc public enum GlassHostKind: Int {
    case instagram = 0
    case genericSupported = 1
    case unsupported = 2
}

@objc public enum GlassSignerKind: Int {
    case unknown = 0
    case ksign = 1
    case esign = 2
    case scarlet = 3
    case feather = 4
    case trollstore = 5
    case sidestore = 6
    case liveContainer = 7
    case otherContainer = 8
}

/// Host / window / Instagram detection — hardened for Live Container guests.
@objc public class GlassAppSupport: NSObject {

    @objc public static let shared = GlassAppSupport()

    private var didWarnUnsupported = false
    private var cachedInstagram: Bool?
    private var cachedContainer: Bool?
    private var cachedSigner: GlassSignerKind?

    @objc public var bundleId: String { Bundle.main.bundleIdentifier ?? "" }

    @objc public var appName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? "Unknown"
    }

    @objc public var executablePath: String { Bundle.main.executablePath ?? "" }

    @objc public var isContainerEnvironment: Bool {
        if let c = cachedContainer { return c }
        let v = detectContainer()
        cachedContainer = v
        return v
    }

    @objc public var isInstagram: Bool {
        // Always re-check in containers — guest classes appear late
        if isContainerEnvironment {
            let v = detectInstagram()
            cachedInstagram = v
            return v
        }
        if let c = cachedInstagram { return c }
        let v = detectInstagram()
        cachedInstagram = v
        return v
    }

    @objc public var hostKind: GlassHostKind {
        isInstagram ? .instagram : .genericSupported
    }

    @objc public var signerKind: GlassSignerKind {
        if let c = cachedSigner { return c }
        let v = detectSigner()
        cachedSigner = v
        return v
    }

    @objc public var signerName: String {
        switch signerKind {
        case .ksign: return "Ksign"
        case .esign: return "Esign"
        case .scarlet: return "Scarlet"
        case .feather: return "Feather"
        case .trollstore: return "TrollStore"
        case .sidestore: return "SideStore"
        case .liveContainer: return "LiveContainer"
        case .otherContainer: return "Container"
        default: return "Unknown"
        }
    }

    // MARK: - Detection

    private func detectContainer() -> Bool {
        let id = bundleId.lowercased()
        let name = appName.lowercased()
        let path = (Bundle.main.bundlePath + " " + executablePath).lowercased()

        let hints = [
            "livecontainer", "live.container", "com.kdt.livecontainer",
            "sidestore", "altstore", "trollstore",
            "containersmanager", "virtualapp", "parallel", "dualspace",
            "island", "shelter", "workprofile", "feather",
            "multiapp", "clone", "dualapp", "appclone", "space"
        ]
        if hints.contains(where: { id.contains($0) || name.contains($0) || path.contains($0) }) {
            return true
        }
        if path.contains("/containers/") ||
            path.contains("application support/containers") ||
            path.contains("livecontainer") ||
            path.contains("/documents/applications/") {
            return true
        }
        // Guest IG inside non-IG host
        if guestInstagramSignals() && !id.contains("instagram") {
            return true
        }
        return false
    }

    private func detectSigner() -> GlassSignerKind {
        let blob = (bundleId + " " + appName + " " + Bundle.main.bundlePath + " " + executablePath).lowercased()
        if blob.contains("livecontainer") || blob.contains("live.container") { return .liveContainer }
        if blob.contains("ksign") { return .ksign }
        if blob.contains("esign") || blob.contains("easy-sign") { return .esign }
        if blob.contains("scarlet") { return .scarlet }
        if blob.contains("feather") { return .feather }
        if blob.contains("trollstore") || blob.contains("troll") { return .trollstore }
        if blob.contains("sidestore") || blob.contains("altstore") { return .sidestore }
        if isContainerEnvironment { return .otherContainer }
        return .unknown
    }

    private func detectInstagram() -> Bool {
        let id = bundleId.lowercased()
        if id.contains("instagram") || id == "com.burbn.instagram" { return true }
        return guestInstagramSignals()
    }

    private func guestInstagramSignals() -> Bool {
        let classNames = [
            "IGViewController", "IGTabBarController", "IGNavigationController",
            "IGUserSession", "IGMainFeedViewController", "IGDirectInbox",
            "IGDirectInboxViewController", "IGDirectThreadViewController",
            "IGProfileViewController", "IGAppDelegate", "IGRootViewController",
            "IGHomeViewController", "IGDirect", "IGFeedItem", "IGUser"
        ]
        for name in classNames {
            if NSClassFromString(name) != nil { return true }
        }

        let imageCount = _gg_dyld_image_count()
        for i in 0..<imageCount {
            if let cname = _gg_dyld_get_image_name(UInt32(i)) {
                let path = String(cString: cname).lowercased()
                if path.contains("instagram") || path.contains("burbn") { return true }
            }
        }

        for b in Bundle.allBundles + Bundle.allFrameworks {
            let bid = (b.bundleIdentifier ?? "").lowercased()
            let bpath = b.bundlePath.lowercased()
            if bid.contains("instagram") || bpath.contains("instagram") || bid.contains("burbn")
                || bid.hasPrefix("com.instagram") {
                return true
            }
        }
        return false
    }

    @objc public func refreshDetection() {
        cachedInstagram = nil
        cachedContainer = nil
        cachedSigner = nil
        _ = isInstagram
        _ = isContainerEnvironment
        _ = signerKind
    }

    // MARK: - Windows / presentation

    @objc public static func allWindows() -> [UIWindow] {
        var result: [UIWindow] = []
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            result.append(contentsOf: ws.windows)
        }
        // Deprecated fallback still useful under some containers
        if result.isEmpty {
            result.append(contentsOf: UIApplication.shared.windows)
        }
        // Include hidden-but-real key candidates if filter wiped everything
        if result.isEmpty {
            for scene in UIApplication.shared.connectedScenes {
                guard let ws = scene as? UIWindowScene else { continue }
                result.append(contentsOf: ws.windows)
            }
        }
        return result.filter { $0.bounds.width > 1 && $0.bounds.height > 1 }
            .sorted { a, b in
                if a.isKeyWindow != b.isKeyWindow { return a.isKeyWindow }
                if a.isHidden != b.isHidden { return !a.isHidden }
                return a.windowLevel.rawValue > b.windowLevel.rawValue
            }
    }

    @objc public static func keyWindow() -> UIWindow? {
        allWindows().first(where: { $0.isKeyWindow && !$0.isHidden })
            ?? allWindows().first(where: { !$0.isHidden })
            ?? allWindows().first
    }

    /// Walk presented chain; never return nil if any VC exists in the hierarchy.
    @objc public static func topViewController() -> UIViewController? {
        let windows = allWindows()
        for window in windows {
            guard var top = window.rootViewController else { continue }
            while let presented = top.presentedViewController {
                top = presented
            }
            // Prefer visible
            if top.viewIfLoaded?.window != nil || window.isKeyWindow {
                return top
            }
            return top
        }
        return nil
    }

    /// Present anything — falls back to a dedicated overlay window if host VC missing.
    @objc public static func presentModally(_ controller: UIViewController, animated: Bool = true) {
        DispatchQueue.main.async {
            if let top = topViewController() {
                // Avoid double-present
                if top.presentedViewController != nil {
                    top.dismiss(animated: false) {
                        top.present(controller, animated: animated)
                    }
                } else {
                    top.present(controller, animated: animated)
                }
                return
            }
            // Fallback overlay window (tweak-safe)
            GlassOverlayPresenter.shared.present(controller, animated: animated)
        }
    }

    @objc public func warnIfUnsupportedIfNeeded() {
        guard !didWarnUnsupported else { return }
        guard !isInstagram else { return }
        guard !GlassDiagnostics.shared.isAttached else { return }

        didWarnUnsupported = true
        DispatchQueue.main.async {
            let note = self.isContainerEnvironment
                ? "\n\nContainer: \(self.signerName). Open the guest fully, then Force Show Glass Button."
                : ""
            let alert = UIAlertController(
                title: "GlossyGlass",
                message: "“\(self.appName)” may not be fully supported.\(note)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            alert.addAction(UIAlertAction(title: "Force Show", style: .default) { _ in
                GlassPreferences.shared.forceShowGlassButton = true
                GlassInjector.forceRedetect()
            })
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                GlassSettingsPresenter.present()
            })
            GlassAppSupport.presentModally(alert)
        }
    }

    @objc public func summary() -> String {
        """
        App: \(appName)
        Bundle: \(bundleId)
        Instagram: \(isInstagram)
        Container: \(isContainerEnvironment)
        Signer: \(signerName)
        Windows: \(GlassAppSupport.allWindows().count)
        """
    }
}

/// High-level overlay window so settings always can appear.
@objc public final class GlassOverlayPresenter: NSObject {
    @objc public static let shared = GlassOverlayPresenter()
    private var window: UIWindow?

    @objc public func present(_ controller: UIViewController, animated: Bool) {
        let win: UIWindow
        if let existing = window, existing.screen != nil {
            win = existing
        } else {
            if let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
                win = UIWindow(windowScene: scene)
            } else {
                win = UIWindow(frame: UIScreen.main.bounds)
            }
            win.windowLevel = UIWindow.Level.alert + 10
            win.backgroundColor = .clear
            let root = UIViewController()
            root.view.backgroundColor = .clear
            win.rootViewController = root
            self.window = win
        }
        win.makeKeyAndVisible()
        win.rootViewController?.present(controller, animated: animated)
    }

    @objc public func dismissOverlay() {
        window?.isHidden = true
        window = nil
    }
}
