import Foundation
import UIKit

/// Bootstrap only. Starts the single chrome owner (GlassUICoordinator).
@objc public class GlassLoader: NSObject {
    @objc public static let shared = GlassLoader()
    private static var once = false
    private static var injectOnce = false

    private override init() { super.init() }

    @objc public static func kick(reason: String = "kick") {
        GlassInstantShield.arm()
        DispatchQueue.main.async {
            GlassLoader.shared.bootstrap(reason: reason)
        }
    }

    private func bootstrap(reason: String) {
        if !GlassLoader.once {
            GlassLoader.once = true
            for name in [
                UIApplication.didBecomeActiveNotification,
                UIApplication.didFinishLaunchingNotification,
                UIScene.didActivateNotification
            ] as [Notification.Name] {
                NotificationCenter.default.addObserver(
                    forName: name, object: nil, queue: .main
                ) { _ in
                    // Soft re-apply only — no full re-bootstrap storm
                    GlassUICoordinator.shared.apply(reason: name.rawValue)
                }
            }
            NSLog("[GlossyGlass] v4.0.0 liquid bootstrap %@", reason as NSString)
        }

        _ = GlassPreferences.shared
        GlassChromeShield.shared.armEarly()
        GlassUICoordinator.shared.start()

        GlassReadyGate.shared.waitUntilReady {
            self.injectOnce()
        }
        if !GlassAppSupport.allWindows().isEmpty {
            injectOnce()
        }

        // One late safety net only
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.injectOnce()
            GlassUICoordinator.shared.apply(reason: "fallback-4s")
        }
    }

    private func injectOnce() {
        if GlassLoader.injectOnce { return }
        GlassLoader.injectOnce = true
        guard !GlassPreferences.shared.safeMode else { return }
        GlassAppSupport.shared.refreshDetection()
        GlassDeviceProfiler.applyIfNeeded()
        GlassInjector.start()
        GlassStyleApplicator.start()
    }
}

@_cdecl("GlassLoaderEntry")
public func GlassLoaderEntry() {
    GlassInstantShield.arm()
    DispatchQueue.main.async { GlassLoader.kick(reason: "GlassLoaderEntry") }
}

@_cdecl("glossyglass_init")
public func glossyglass_init() {
    GlassInstantShield.arm()
    DispatchQueue.main.async { GlassLoader.kick(reason: "glossyglass_init") }
}

@_cdecl("TweakInitialize")
public func TweakInitialize() {
    GlassInstantShield.arm()
    DispatchQueue.main.async { GlassLoader.kick(reason: "TweakInitialize") }
}

@_cdecl("Initialize")
public func Initialize() {
    GlassInstantShield.arm()
    DispatchQueue.main.async { GlassLoader.kick(reason: "Initialize") }
}
