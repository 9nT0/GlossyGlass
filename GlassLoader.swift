import Foundation
import UIKit

@objc public class GlassLoader: NSObject {

    @objc public static let shared = GlassLoader()

    private override init() {
        super.init()
        start()
    }

    private func start() {
        let delays: [TimeInterval] = [1.0, 2.5, 5.0]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                GlassInjector.start()
            }
        }

        // First launch guide
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            GlassFirstLaunch.checkAndShowIfNeeded()
        }

        NSLog("[GlossyGlass] v2 Loader initialized")
    }
}

private let __glassLoad: Void = {
    DispatchQueue.main.async {
        _ = GlassLoader.shared
    }
}()
