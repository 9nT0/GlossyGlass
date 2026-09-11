import Foundation
import UIKit

@objc public class GlassLoader: NSObject {

    @objc public static let shared = GlassLoader()
    private static var bootstrapOnce = false
    private static var observersArmed = false

    private override init() { super.init() }

    @objc public static func kick(reason: String = "kick") {
        // Instant shield first — before anything else
        GlassInstantShield.arm()
        DispatchQueue.main.async {
            GlassLoader.shared.bootstrapIfNeeded(reason: reason)
        }
    }

    private func bootstrapIfNeeded(reason: String) {
        GlassInstantShield.arm()
        if !GlassLoader.bootstrapOnce {
            GlassLoader.bootstrapOnce = true
            armObservers()
            NSLog("[GlossyGlass] bootstrap %@", reason as NSString)
        }
        launch(reason: reason)
    }

    private func armObservers() {
        guard !GlassLoader.observersArmed else { return }
        GlassLoader.observersArmed = true
        for name in [
            UIApplication.didBecomeActiveNotification,
            UIApplication.didFinishLaunchingNotification,
            UIScene.didActivateNotification
        ] as [Notification.Name] {
            NotificationCenter.default.addObserver(
                forName: name, object: nil, queue: .main
            ) { _ in GlassLoader.kick(reason: name.rawValue) }
        }
    }

    private func launch(reason: String) {
        // One chrome owner
        GlassChromeCoordinator.shared.start()
        GlassContextChrome.shared.start()

        GlassReadyGate.shared.waitUntilReady {
            self.startInjector(tag: "gate")
        }
        if !GlassAppSupport.allWindows().isEmpty {
            startInjector(tag: "windows-\(reason)")
        }
        // Quiet injector only — no chrome thrash
        for d in [2.0, 6.0] as [TimeInterval] {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                if !GlassDiagnostics.shared.isAttached {
                    self.startInjector(tag: "retry-\(d)")
                }
            }
        }
    }

    private func startInjector(tag: String) {
        if GlassPreferences.shared.safeMode { return }
        GlassAppSupport.shared.refreshDetection()
        GlassDeviceProfiler.applyIfNeeded()
        GlassInjector.start()
        GlassStyleApplicator.start()
        NSLog("[GlossyGlass] injector %@", tag as NSString)
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
