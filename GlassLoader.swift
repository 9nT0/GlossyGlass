import Foundation
import UIKit

/// v3.6.1 — container-friendly auto-start (Live Container, multi-scene hosts)
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

        DispatchQueue.main.async { self.launch(reason: "immediate") }

        // Longer, denser schedule for containers (guest UI appears late)
        let delays: [TimeInterval] = [
            0.2, 0.5, 0.9, 1.4, 2.0, 3.0, 4.5, 6.0, 8.0, 11.0, 15.0, 20.0, 28.0, 40.0
        ]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.launch(reason: "retry-\(delay)")
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            GlassAppSupport.shared.refreshDetection()
            self.launch(reason: "active")
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { _ in
            GlassAppSupport.shared.refreshDetection()
            self.launch(reason: "didFinishLaunching")
        }

        // Scene activation — critical for containers
        NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { _ in
            GlassAppSupport.shared.refreshDetection()
            self.launch(reason: "sceneActivate")
        }

        NotificationCenter.default.addObserver(
            forName: UIScene.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.launch(reason: "sceneForeground")
        }

        NSLog("[GlossyGlass] Loader v3.6.1 initialized (container-aware)")
    }

    private func launch(reason: String) {
        if GlassPreferences.shared.safeMode {
            NSLog("[GlossyGlass] Safe mode — skip (\(reason))")
            return
        }
        GlassDeviceProfiler.applyIfNeeded()
        GlassInjector.start()
        GlassStyleApplicator.start()
        GlassScreenProfileMonitor.start()
        NSLog("[GlossyGlass] launch reason=\(reason) ig=\(GlassAppSupport.shared.isInstagram) container=\(GlassAppSupport.shared.isContainerEnvironment)")
    }
}

@_cdecl("GlassLoaderEntry")
public func GlassLoaderEntry() {
    _ = GlassLoader.shared
}

@_cdecl("glossyglass_init")
public func glossyglass_init() {
    _ = GlassLoader.shared
}

// Extra symbols some container injectors look for
@_cdecl("TweakInitialize")
public func TweakInitialize() {
    _ = GlassLoader.shared
}

@_cdecl("Initialize")
public func Initialize() {
    _ = GlassLoader.shared
}

private let __glassAutoLoad: Void = {
    DispatchQueue.global(qos: .userInitiated).async {
        DispatchQueue.main.async {
            _ = GlassLoader.shared
        }
    }
}()
