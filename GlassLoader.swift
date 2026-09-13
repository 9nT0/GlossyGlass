import Foundation
import UIKit

@objc public class GlassLoader: NSObject {
    @objc public static let shared = GlassLoader()
    private static var once = false

    private override init() { super.init() }

    @objc public static func kick(reason: String = "kick") {
        GlassInstantShield.arm()
        GlassChromeShield.shared.armEarly()
        DispatchQueue.main.async {
            GlassLoader.shared.bootstrap(reason: reason)
        }
    }

    private func bootstrap(reason: String) {
        GlassInstantShield.arm()
        if !GlassLoader.once {
            GlassLoader.once = true
            for name in [
                UIApplication.didBecomeActiveNotification,
                UIApplication.didFinishLaunchingNotification,
                UIScene.didActivateNotification
            ] as [Notification.Name] {
                NotificationCenter.default.addObserver(
                    forName: name, object: nil, queue: .main
                ) { _ in GlassLoader.kick(reason: name.rawValue) }
            }
            NSLog("[GlossyGlass] v4 liquid bootstrap %@", reason as NSString)
        }
        // Single owner
        GlassUICoordinator.shared.start()
        GlassReadyGate.shared.waitUntilReady {
            self.inject()
        }
        if !GlassAppSupport.allWindows().isEmpty {
            inject()
        }
        for d in [1.5, 5.0] as [TimeInterval] {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                if !GlassDiagnostics.shared.isAttached { self.inject() }
                GlassUICoordinator.shared.apply(reason: "fallback")
            }
        }
    }

    private func inject() {
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
