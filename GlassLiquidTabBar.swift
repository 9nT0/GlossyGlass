import UIKit
@objc public final class GlassLiquidTabBar: NSObject {
    @objc public static let shared = GlassLiquidTabBar()
    @objc public func start() { GlassDock.shared.attachIfNeeded() }
    @objc public func refresh() { GlassDock.shared.attachIfNeeded() }
}
