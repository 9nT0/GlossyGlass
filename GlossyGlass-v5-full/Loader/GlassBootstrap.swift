import UIKit

@objc public final class GlassBootstrap: NSObject {
    private static var started = false

    @objc public static func start() {
        DispatchQueue.main.async {
            guard !started else { return }
            started = true
            NSLog("[GlossyGlass v5.1] Bootstrap")
            _ = GlassPreferences.shared
            IGHooks.shared.start()
            GlassReady.shared.waitUntilReady {
                NSLog("[GlossyGlass v5.1] Host ready")
                GlassChrome.shared.start()
            }
        }
    }
}
