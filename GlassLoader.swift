import Foundation
import UIKit

/// Forces automatic start when the dylib is loaded.
/// Compatible with iOS 17 – 18.x
@objc public class GlassLoader: NSObject {

    @objc public static let shared = GlassLoader()

    private override init() {
        super.init()
        start()
    }

    private func start() {
        // Multiple delayed attempts so the host app UI is ready
        let delays: [TimeInterval] = [1.2, 2.8, 5.0]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                GlassInjector.start()
            }
        }
        NSLog("[GlossyGlass] Loader initialized")
    }
}

// This runs as soon as the image is loaded into the process
@_cdecl("GlassLoaderEntry")
func GlassLoaderEntry() {
    _ = GlassLoader.shared
}

// Fallback static that most Swift runtimes will execute
private let __glassLoad: Void = {
    DispatchQueue.main.async {
        _ = GlassLoader.shared
    }
}()
