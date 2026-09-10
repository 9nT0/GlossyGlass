import Foundation
import UIKit

/// Bootstrap only. Visual chrome is GlassChromeCoordinator.
/// Injector attaches settings control. No multi-second visual assembly spam.
@objc public class GlassLoader: NSObject {

    @objc public static let shared = GlassLoader()

    private static var bootstrapOnce = false
    private static var observersArmed = false

    private override init() { super.init() }

    @objc public static func kick(reason: String = "kick") {
        DispatchQueue.main.async {
            GlassLoader.shared.bootstrapIfNeeded(reason: reason)
        }
    }

    private func bootstrapIfNeeded(reason: String) {
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
        let windows = GlassAppSupport.allWindows()
        if windows.isEmpty && reason.contains("immediate") { return }

        // VISUAL PATH — immediate coordinator (not delayed 45s assembly)
        GlassChromeCoordinator.shared.start()

        // BOOTSTRAP PATH — settings button inject (can retry quietly)
        GlassReadyGate.shared.waitUntilReady {
            self.startInjector(tag: "gate")
        }
        if !windows.isEmpty {
            startInjector(tag: "windows-\(reason)")
        }
        // Quiet injector retries — does not rebuild chrome every time
        for d in [1.5, 4.0, 10.0] as [TimeInterval] {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                if !GlassDiagnostics.shared.isAttached {
                    self.startInjector(tag: "retry-\(d)")
                }
                GlassChromeCoordinator.shared.apply(reason: "fallback")
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
    DispatchQueue.main.async { GlassLoader.kick(reason: "GlassLoaderEntry") }
}

@_cdecl("glossyglass_init")
public func glossyglass_init() {
    DispatchQueue.main.async { GlassLoader.kick(reason: "glossyglass_init") }
}

@_cdecl("TweakInitialize")
public func TweakInitialize() {
    DispatchQueue.main.async { GlassLoader.kick(reason: "TweakInitialize") }
}

@_cdecl("Initialize")
public func Initialize() {
    DispatchQueue.main.async { GlassLoader.kick(reason: "Initialize") }
}
