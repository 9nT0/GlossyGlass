import UIKit
@objc public final class GlassLiquidTabBar: NSObject {
    @objc public static let shared = GlassLiquidTabBar()
    private override init() { super.init() }
    @objc public func start() { GlassChromeCoordinator.shared.start() }
    @objc public func refresh() { GlassChromeCoordinator.shared.apply(reason: "liquidTab") }
}
