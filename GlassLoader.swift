import Foundation
import UIKit

@objc public class GlassLoader: NSObject {

    @objc public static let shared = GlassLoader()

    private static var observersArmed = false
    private static var bootstrapOnce = false
    private static var welcomeShown = false
    private static var coreCount = 0

    private override init() {
        super.init()
        NSLog("[GlossyGlass] GlassLoader.shared init")
        bootstrap()
    }

    @objc public static func kick(reason: String = "kick") {
        NSLog("[GlossyGlass] kick: %@", reason)
        DispatchQueue.main.async {
            GlassLoader.shared.startCore(reason: reason)
        }
    }

    private func bootstrap() {
        armObserversIfNeeded()
        if !GlassLoader.bootstrapOnce {
            GlassLoader.bootstrapOnce = true
            NSLog("[GlossyGlass] Loader v4.1 bootstrap")
        }

        DispatchQueue.main.async {
            self.startCore(reason: "immediate")
        }

        let delays: [TimeInterval] = [0.2, 0.5, 1.0, 2.0, 4.0, 8.0, 15.0, 25.0, 40.0]
        for d in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                self.startCore(reason: "retry-\(d)")
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
                self.startCore(reason: name.rawValue)
            }
        }
    }

    @objc public func startCore(reason: String) {
        GlassLoader.coreCount += 1
        if GlassPreferences.shared.safeMode {
            NSLog("[GlossyGlass] safe mode — skip %@", reason)
            return
        }

        GlassAppSupport.shared.refreshDetection()
        armObserversIfNeeded()

        // Always start systems (idempotent)
        GlassDeviceProfiler.applyIfNeeded()
        GlassInjector.start()
        GlassStyleApplicator.start()
        GlassScreenProfileMonitor.start()

        showWelcomeIfPossible()

        GlassReadyGate.shared.waitUntilReady {
            GlassInjector.start()
            GlassStyleApplicator.applyAll()
            self.showWelcomeIfPossible()
        }

        NSLog("[GlossyGlass] startCore #%d %@ ig=%d win=%d",
              GlassLoader.coreCount, reason as NSString,
              GlassAppSupport.shared.isInstagram ? 1 : 0,
              GlassAppSupport.allWindows().count)
    }

    private func showWelcomeIfPossible() {
        let windows = GlassAppSupport.allWindows()
        guard !windows.isEmpty else { return }
        if GlassLoader.welcomeShown { return }
        GlassLoader.welcomeShown = true
        GlassWelcome.present(force: true)
    }
}

// MARK: - Load-time triggers

private enum GlassLoadTrigger {
    static let arm: Void = {
        NSLog("[GlossyGlass] Swift LoadTrigger arm")
        DispatchQueue.main.async {
            _ = GlassLoader.shared
            GlassLoader.kick(reason: "LoadTrigger")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            GlassLoader.kick(reason: "LoadTrigger+1s")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            GlassLoader.kick(reason: "LoadTrigger+3s")
        }
    }()
}

@_cdecl("GlassLoaderEntry")
public func GlassLoaderEntry() {
    _ = GlassLoadTrigger.arm
    GlassLoader.kick(reason: "GlassLoaderEntry")
}

@_cdecl("glossyglass_init")
public func glossyglass_init() {
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

// Force static init when module loads
private let __glassAutoLoad: Void = {
    _ = GlassLoadTrigger.arm
}()
