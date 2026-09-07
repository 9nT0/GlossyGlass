import Foundation
import UIKit

/// Robust auto-start for every major sideloading / injection path.
/// Works with: Ksign, Esign, Scarlet, Feather, TrollStore-style injectors,
/// and generic dylib injection (constructor + Swift static + delayed retries).
@objc public class GlassLoader: NSObject {

    @objc public static let shared = GlassLoader()
    private static var didStart = false

    private override init() {
        super.init()
        bootstrap()
    }

    private func bootstrap() {
        guard !GlassLoader.didStart else { return }
        GlassLoader.didStart = true

        // Immediate attempt (some injectors load late into a ready process)
        DispatchQueue.main.async {
            self.launch()
        }

        // Staggered retries — covers cold launch, late UI, signer differences
        let delays: [TimeInterval] = [0.3, 0.8, 1.5, 2.5, 4.0, 6.5, 10.0, 15.0]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.launch()
            }
        }

        // Also listen for active — covers background→foreground
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.launch()
        }

        NSLog("[GlossyGlass] Loader v3.1 initialized")
    }

    private func launch() {
        if GlassPreferences.shared.safeMode {
            NSLog("[GlossyGlass] Safe mode — injection skipped")
            return
        }
        GlassInjector.start()
    }
}

// Classic C constructor — works with most dyld injectors / signers
@_cdecl("GlassLoaderEntry")
public func GlassLoaderEntry() {
    _ = GlassLoader.shared
}

// Extra C-compatible symbol some injectors look for
@_cdecl("glossyglass_init")
public func glossyglass_init() {
    _ = GlassLoader.shared
}

// Swift static initializer — runs when the image is loaded by the runtime
private let __glassAutoLoad: Void = {
    // Use async so we don't block dyld
    DispatchQueue.global(qos: .userInitiated).async {
        DispatchQueue.main.async {
            _ = GlassLoader.shared
        }
    }
}()
