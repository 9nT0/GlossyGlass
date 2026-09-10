import Foundation
import UIKit

/// Safe load bootstrap — no work until main queue + app is up.
@objc public class GlassLoader: NSObject {

    @objc public static let shared = GlassLoader()

    private static var observersArmed = false
    private static var bootstrapOnce = false
    private static var hardStartArmed = false
    private static var launchOnce = false

    private override init() {
        super.init()
        // Do not bootstrap from init — wait for explicit kick from ObjC after launch
    }

    @objc public static func kick(reason: String = "kick") {
        DispatchQueue.main.async {
            GlassLoader.shared.bootstrapIfNeeded(reason: reason)
        }
    }

    private func bootstrapIfNeeded(reason: String) {
        if !GlassLoader.bootstrapOnce {
            GlassLoader.bootstrapOnce = true
            armObserversIfNeeded()
            armHardStartFallback()
            NSLog("[GlossyGlass] Loader v4.0.2 bootstrap (%@)", reason as NSString)
            logEnvironment(tag: "bootstrap")
        }
        launch(reason: reason)
    }

    private func armHardStartFallback() {
        guard !GlassLoader.hardStartArmed else { return }
        GlassLoader.hardStartArmed = true
        for d in [3.0, 8.0, 15.0] as [TimeInterval] {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                if GlassPreferences.shared.safeMode { return }
                NSLog("[GlossyGlass] hard-start @%.0fs", d)
                self.startCore(tag: "hard-\(d)")
            }
        }
    }

    private func armObserversIfNeeded() {
        guard !GlassLoader.observersArmed else { return }
        GlassLoader.observersArmed = true

        let names: [Notification.Name] = [
            UIApplication.didBecomeActiveNotification,
            UIApplication.didFinishLaunchingNotification,
            UIScene.didActivateNotification
        ]
        for name in names {
            NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { _ in
                GlassLoader.kick(reason: name.rawValue)
            }
        }
    }

    private func launch(reason: String) {
        // Wait until we have a real app + preferably a window
        let app = UIApplication.shared
        _ = app
        let windows = GlassAppSupport.allWindows()
        if windows.isEmpty && reason.contains("immediate") {
            // Too early — hard-start / retries will pick it up
            NSLog("[GlossyGlass] launch skipped (no windows) reason=%@", reason as NSString)
            return
        }

        GlassReadyGate.shared.waitUntilReady {
            self.startCore(tag: "gate-\(reason)")
        }

        // Also start once windows exist without waiting forever
        if !windows.isEmpty {
            startCore(tag: "windows-\(reason)")
        }
    }

    private func startCore(tag: String) {
        if GlassPreferences.shared.safeMode {
            NSLog("[GlossyGlass] safe mode — no inject")
            return
        }
        NSLog("[GlossyGlass] startCore %@", tag as NSString)
        GlassAppSupport.shared.refreshDetection()
        GlassDeviceProfiler.applyIfNeeded()
        GlassInjector.start()
        GlassStyleApplicator.start()
        GlassLiquidTabBar.shared.start()
        GlassScreenProfileMonitor.start()
        logEnvironment(tag: tag)

        // Welcome only once, delayed
        if !GlassLoader.launchOnce {
            GlassLoader.launchOnce = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                GlassWelcome.presentIfNeeded()
                GlassFirstLaunch.checkAndShowIfNeeded()
            }
        }
    }

    private func logEnvironment(tag: String) {
        let s = GlassAppSupport.shared
        let d = GlassDiagnostics.shared
        NSLog(
            "[GlossyGlass][%@] bundle=%@ ig=%d container=%d signer=%@ attached=%d score=%d windows=%d",
            tag as NSString,
            s.bundleId as NSString,
            s.isInstagram ? 1 : 0,
            s.isContainerEnvironment ? 1 : 0,
            s.signerName as NSString,
            d.isAttached ? 1 : 0,
            d.lastScore,
            GlassAppSupport.allWindows().count
        )
    }
}

// MARK: - C exports (ObjC / injectors)

@_cdecl("GlassLoaderEntry")
public func GlassLoaderEntry() {
    DispatchQueue.main.async {
        GlassLoader.kick(reason: "GlassLoaderEntry")
    }
}

@_cdecl("glossyglass_init")
public func glossyglass_init() {
    DispatchQueue.main.async {
        GlassLoader.kick(reason: "glossyglass_init")
    }
}

@_cdecl("TweakInitialize")
public func TweakInitialize() {
    DispatchQueue.main.async {
        GlassLoader.kick(reason: "TweakInitialize")
    }
}

@_cdecl("Initialize")
public func Initialize() {
    DispatchQueue.main.async {
        GlassLoader.kick(reason: "Initialize")
    }
}
