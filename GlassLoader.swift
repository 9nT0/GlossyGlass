import Foundation
import UIKit

/// v3.6.1 — Live Container reliable load
@objc public class GlassLoader: NSObject {

    @objc public static let shared = GlassLoader()

    private static var observersArmed = false
    private static var bootstrapOnce = false

    private override init() {
        super.init()
        bootstrap()
    }

    /// Safe to call many times (scene activate / LC late UI)
    @objc public static func kick(reason: String = "kick") {
        GlassLoader.shared.launch(reason: reason)
    }

    private func bootstrap() {
        if !GlassLoader.bootstrapOnce {
            GlassLoader.bootstrapOnce = true
            armObserversIfNeeded()
            NSLog("[GlossyGlass] Loader v4.0.1 bootstrap (container-aware)")
            logEnvironment(tag: "bootstrap")
        }

        DispatchQueue.main.async { self.launch(reason: "immediate") }

        // Dense early + long tail — Live Container guest UI is often late
        let delays: [TimeInterval] = GlassAppSupport.shared.isContainerEnvironment
            ? [0.2, 0.5, 1.0, 1.8, 3.0, 5.0, 8.0, 12.0, 18.0, 25.0, 35.0, 50.0, 60.0]
            : [0.3, 0.8, 1.5, 2.5, 4.0, 6.0, 9.0, 12.0, 16.0, 22.0, 30.0, 40.0, 55.0]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.launch(reason: "retry-\(delay)")
            }
        }
    }

    private func armObserversIfNeeded() {
        guard !GlassLoader.observersArmed else { return }
        GlassLoader.observersArmed = true

        let names: [Notification.Name] = [
            UIApplication.didBecomeActiveNotification,
            UIApplication.didFinishLaunchingNotification,
            UIScene.didActivateNotification,
            UIScene.willEnterForegroundNotification
        ]
        for name in names {
            NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { _ in
                GlassAppSupport.shared.refreshDetection()
                GlassLoader.shared.launch(reason: name.rawValue)
            }
        }
    }

    private func launch(reason: String) {
        if GlassPreferences.shared.safeMode {
            NSLog("[GlossyGlass] Safe mode — skip (\(reason))")
            return
        }

        GlassAppSupport.shared.refreshDetection()
        armObserversIfNeeded()

        GlassReadyGate.shared.waitUntilReady {
            GlassDeviceProfiler.applyIfNeeded()
            // Container: if still not Instagram-flagged but IG classes appear mid-wait, refresh again
            GlassAppSupport.shared.refreshDetection()
            GlassInjector.start()
            GlassStyleApplicator.start()
            GlassScreenProfileMonitor.start()
            self.logEnvironment(tag: "launch-\(reason)")
        }
    }

    private func logEnvironment(tag: String) {
        let s = GlassAppSupport.shared
        let d = GlassDiagnostics.shared
        NSLog(
            "[GlossyGlass][%@] bundle=%@ ig=%d container=%d signer=%@ attached=%d score=%d forceShow=%d",
            tag,
            s.bundleId,
            s.isInstagram ? 1 : 0,
            s.isContainerEnvironment ? 1 : 0,
            s.signerName,
            d.isAttached ? 1 : 0,
            d.lastScore,
            GlassPreferences.shared.forceShowGlassButton ? 1 : 0
        )
    }
}

// MARK: - Image-load entry (closest to +load)

private enum GlassLoadTrigger {
    static let arm: Void = {
        DispatchQueue.main.async {
            _ = GlassLoader.shared
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            GlassLoader.kick(reason: "LoadTrigger+1s")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            GlassLoader.kick(reason: "LoadTrigger+5s")
        }
    }()
}

@_cdecl("GlassLoaderEntry")
public func GlassLoaderEntry() {
    _ = GlassLoadTrigger.arm
    _ = GlassLoader.shared
}

@_cdecl("glossyglass_init")
public func glossyglass_init() {
    _ = GlassLoadTrigger.arm
    GlassLoader.kick(reason: "glossyglass_init")
}

@_cdecl("TweakInitialize")
public func TweakInitialize() {
    GlassLoader.kick(reason: "TweakInitialize")
}

@_cdecl("Initialize")
public func Initialize() {
    GlassLoader.kick(reason: "Initialize")
}

private let __glassAutoLoad: Void = {
    _ = GlassLoadTrigger.arm
}()
