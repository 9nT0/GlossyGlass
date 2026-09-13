import UIKit
@objc public final class GlassFloatingTabGlass: NSObject {
    @objc public static let shared = GlassFloatingTabGlass()
    @objc public func attachIfNeeded() { GlassDock.shared.attachIfNeeded() }
}
