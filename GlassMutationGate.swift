import Foundation

/// Optional suspend during rare races. Defaults to open so chrome always loads.
@objc public final class GlassMutationGate: NSObject {
    @objc public static var isSuspended = false
    private static let lock = NSLock()

    @objc public static func suspend() {
        // Disabled: suspending blocked chrome when settings present failed.
        // Keep API but do not block mutations.
        lock.lock(); isSuspended = false; lock.unlock()
    }

    @objc public static func resume() {
        lock.lock(); isSuspended = false; lock.unlock()
        DispatchQueue.main.async {
            GlassChromeCoordinator.shared.apply(reason: "resume")
            GlassDock.shared.attachIfNeeded()
        }
    }
}
