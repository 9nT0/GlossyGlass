import Foundation
import UIKit

/// GlossyGlass load bootstrap — works standalone and under DylibLoader / Live Container.
@objc public class GlassLoader: NSObject {

    @objc public static let shared = GlassLoader()

    private static var observersArmed = false
    private static var bootstrapOnce = false
    private static var hardStartArmed = false

    private override init() {
        super.init()
        bootstrap()
    }

    @objc public static func kick(reason: String = "kick") {
        GlassLoader.shared.launch(reason: reason)
    }

    private func bootstrap() {
        if !GlassLoader.bootstrapOnce {
            GlassLoader.bootstrapOnce = true
            armObserversIfNeeded()
            NSLog("[GlossyGlass] Loader v4.0.2 bootstrap")
            logEnvironment(tag: "bootstrap")
            armHardStartFallback()
        }

        DispatchQueue.main.async { self.launch(reason: "immediate") }

        // Always dense — container detection can be wrong at constructor time
        let delays: [TimeInterval] = [
            0.15, 0.4, 0.8, 1.2, 2.0, 3.0, 5.0, 8.0,
            12.0, 18.0, 25.0, 35.0, 50.0, 70.0
        ]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.launch(reason: "retry-\(delay)")
            }
        }
    }

    /// Parallel path: force injector even if ReadyGate is stuck
    private func armHardStartFallback() {
        guard !GlassLoader.hardStartArmed else { return }
        GlassLoader.hardStartArmed = true
        let hardDelays: [TimeInterval] = [2.0, 5.0, 10.0, 20.0]
        for d in hardDelays {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                if GlassPreferences.shared.safeMode { return }
                NSLog("[GlossyGlass] hard-start injector @%.0fs", d)
                GlassAppSupport.shared.refreshDetection()
                GlassDeviceProfiler.applyIfNeeded()
                GlassInjector.start()
                GlassStyleApplicator.start()
                GlassLiquidTabBar.shared.start()
                _ = GlassIGScanner.shared.scan()
                _ = GGEmbedded_EnsureLUT()
                GlassScreenProfileMonitor.start()
                GlassWelcome.presentIfNeeded()
                GlassFirstLaunch.checkAndShowIfNeeded()
                if GlassAppSupport.shared.isContainerEnvironment,
                   !GlassDiagnostics.shared.isAttached {
                    GlassPreferences.shared.forceShowGlassButton = true
                    GlassInjector.forceRedetect()
                }
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
                forName: name, object: nil, queue: .main
            ) { _ in
                GlassAppSupport.shared.refreshDetection()
                GlassLoader.shared.launch(reason: name.rawValue)
            }
        }
    }

    private func launch(reason: String) {
        if GlassPreferences.shared.safeMode {
            NSLog("[GlossyGlass] Safe mode — skip (%@)", reason as NSString)
            return
        }

        GlassAppSupport.shared.refreshDetection()
        armObserversIfNeeded()

        GlassReadyGate.shared.waitUntilReady {
            GlassDeviceProfiler.applyIfNeeded()
            GlassAppSupport.shared.refreshDetection()
            GlassInjector.start()
            GlassStyleApplicator.start()
                GlassLiquidTabBar.shared.start()
                _ = GlassIGScanner.shared.scan()
                _ = GGEmbedded_EnsureLUT()
            GlassScreenProfileMonitor.start()
            GlassWelcome.presentIfNeeded()
            GlassFirstLaunch.checkAndShowIfNeeded()
            self.logEnvironment(tag: "launch-\(reason)")
        }

        // Immediate path if windows already exist
        if !GlassAppSupport.allWindows().isEmpty {
            GlassDeviceProfiler.applyIfNeeded()
            GlassInjector.start()
            GlassStyleApplicator.start()
                GlassLiquidTabBar.shared.start()
                _ = GlassIGScanner.shared.scan()
                _ = GGEmbedded_EnsureLUT()
        }
    }

    private func logEnvironment(tag: String) {
        let s = GlassAppSupport.shared
        let d = GlassDiagnostics.shared
        NSLog(
            "[GlossyGlass][%@] bundle=%@ ig=%d container=%d signer=%@ attached=%d score=%d forceShow=%d windows=%d",
            tag as NSString,
            s.bundleId as NSString,
            s.isInstagram ? 1 : 0,
            s.isContainerEnvironment ? 1 : 0,
            s.signerName as NSString,
            d.isAttached ? 1 : 0,
            d.lastScore,
            GlassPreferences.shared.forceShowGlassButton ? 1 : 0,
            GlassAppSupport.allWindows().count
        )
    }
}

private enum GlassLoadTrigger {
    static let arm: Void = {
        NSLog("[GlossyGlass] Swift LoadTrigger arm")
        DispatchQueue.main.async {
            _ = GlassLoader.shared
            GlassLoader.kick(reason: "LoadTrigger")
        }
        for d in [1.0, 3.0, 8.0, 15.0] as [TimeInterval] {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                GlassLoader.kick(reason: "LoadTrigger+\(d)")
            }
        }
    }()
}

@_cdecl("GlassLoaderEntry")
public func GlassLoaderEntry() {
    _ = GlassLoadTrigger.arm
    DispatchQueue.main.async {
        _ = GlassLoader.shared
        GlassLoader.kick(reason: "GlassLoaderEntry")
    }
}

@_cdecl("glossyglass_init")
public func glossyglass_init() {
    _ = GlassLoadTrigger.arm
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

private let __glassAutoLoad: Void = {
    _ = GlassLoadTrigger.arm
}()
