import UIKit

@objc(GlassBootstrap)
public final class GlassBootstrap: NSObject {
    private static var started = false

    @objc public static func start() {
        DispatchQueue.main.async {
            guard !started else { return }
            started = true
            NSLog("[GlossyGlass] Bootstrap")
            _ = GlassPreferences.shared
            IGHooks.shared.start()
            GlassContextHooks.shared.start()
            GlassReady.shared.waitUntilReady {
                NSLog("[GlossyGlass] Ready")
                GlassChrome.shared.start()
            }
        }
    }
}
