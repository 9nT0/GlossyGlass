import UIKit
import Darwin

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

    @objc public var executablePath: String {
        Bundle.main.executablePath ?? ""
    }

    @objc public var isContainerEnvironment: Bool {
        if let c = cachedContainer { return c }
        let v = detectContainer()
        cachedContainer = v
        return v
    }

    @objc public var isInstagram: Bool {
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
            "island", "shelter", "workprofile", "feather"
        ]
        if hints.contains(where: { id.contains($0) || name.contains($0) || path.contains($0) }) {
            return true
        }
        if path.contains("/containers/") || path.contains("application support/containers") {
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
            "IGHomeViewController", "IGDirect"
        ]
        for name in classNames {
            if NSClassFromString(name) != nil { return true }
        }

        let imageCount = _dyld_image_count()
        for i in 0..<imageCount {
            if let cname = _dyld_get_image_name(i) {
                let path = String(cString: cname).lowercased()
                if path.contains("instagram") || path.contains("burbn") { return true }
            }
        }

        for b in Bundle.allBundles {
            let bid = (b.bundleIdentifier ?? "").lowercased()
            let bpath = b.bundlePath.lowercased()
            if bid.contains("instagram") || bpath.contains("instagram") || bid.contains("burbn") {
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

    // MARK: - Windows / presentation (container-safe)

    @objc public static func allWindows() -> [UIWindow] {
        var result: [UIWindow] = []
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            result.append(contentsOf: ws.windows)
        }
        if result.isEmpty {
            result.append(contentsOf: UIApplication.shared.windows)
        }
        return result.filter { !$0.isHidden && $0.alpha > 0.01 && $0.bounds.width > 1 }
    }

    @objc public static func topViewController() -> UIViewController? {
        let windows = allWindows().sorted { a, b in
            // Prefer key + larger
            if a.isKeyWindow != b.isKeyWindow { return a.isKeyWindow }
            return a.bounds.width * a.bounds.height > b.bounds.width * b.bounds.height
        }
        guard var top = windows.first?.rootViewController else { return nil }
        while let p = top.presentedViewController { top = p }
        return top
    }

    @objc public func warnIfUnsupportedIfNeeded() {
        guard !didWarnUnsupported else { return }
        guard !isInstagram else { return }
        guard !GlassDiagnostics.shared.isAttached else { return }
        guard GlassDiagnostics.shared.lastScore < 20 else { return }

        didWarnUnsupported = true
        DispatchQueue.main.async {
            let note = self.isContainerEnvironment
                ? "\n\nContainer: \(self.signerName). If the guest is Instagram, open it fully and enable Force Show Glass Button."
                : ""
            let alert = UIAlertController(
                title: "GlossyGlass",
                message: "“\(self.appName)” may not be fully supported.\(note)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            alert.addAction(UIAlertAction(title: "Force Show Button", style: .default) { _ in
                GlassPreferences.shared.forceShowGlassButton = true
                GlassInjector.forceRedetect()
            })
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                GlassSettingsPresenter.present()
            })
            GlassAppSupport.topViewController()?.present(alert, animated: true)
        }
    }

    @objc public func summary() -> String {
        """
        App: \(appName)
        Bundle: \(bundleId)
        Instagram: \(isInstagram)
        Container: \(isContainerEnvironment)
        Signer: \(signerName)
        """
    }
}
