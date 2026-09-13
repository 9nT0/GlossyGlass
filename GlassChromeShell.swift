import UIKit
@objc public final class GlassChromeShell: NSObject {
    @objc public static let shared = GlassChromeShell()
    @objc public func start() { GlassUICoordinator.shared.start() }
    @objc public func reassert() { GlassUICoordinator.shared.apply(reason: "shell") }
    @objc public func paintIfChrome(_ view: UIView) { GlassUICoordinator.shared.paintIfChrome(view) }
}
@objc public enum GlassChromeRole: Int { case nav = 0, tab = 1, header = 2 }
