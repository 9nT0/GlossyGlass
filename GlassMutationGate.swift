import Foundation

/// Serializes chrome mutations. Suspend while settings panel is open to prevent crash races.
@objc public final class GlassMutationGate: NSObject {
    @objc public static var isSuspended = false
    private static let lock = NSLock()

    @objc public static func suspend() {
        lock.lock(); isSuspended = true; lock.unlock()
    }

    @objc public static func resume() {
        lock.lock(); isSuspended = false; lock.unlock()
        DispatchQueue.main.async {
            GlassChromeCoordinator.shared.apply(reason: "resume")
        }
    }
}
