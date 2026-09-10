import UIKit

/// Compatibility — curved tab glass lives in GlassMaterialEngine via Coordinator.
@objc public final class GlassFloatingTabGlass: NSObject {
    @objc public static let shared = GlassFloatingTabGlass()
    private override init() { super.init() }
    @objc public func attachIfNeeded() {
        GlassChromeCoordinator.shared.apply(reason: "floating")
    }
}
