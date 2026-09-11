import UIKit
@objc public final class GlassChromeShell: NSObject {
    @objc public static let shared = GlassChromeShell()
    private override init() { super.init() }
    @objc public func start() { GlassChromeCoordinator.shared.start() }
    @objc public func reassert() {
        guard !GlassMutationGate.isSuspended else { return }
        GlassChromeCoordinator.shared.apply(reason: "reassert")
    }
    @objc public func paintIfChrome(_ view: UIView) {
        GlassChromeCoordinator.shared.paintIfChrome(view)
    }
}
@objc public enum GlassChromeRole: Int {
    case nav = 0, tab = 1, header = 2
}
