import Foundation
import UIKit

@objc public class GlassLoader: NSObject {

    @objc public static let shared = GlassLoader()
    private static var observersArmed = false
    private static var bootstrapOnce = false
    private static var welcomeShown = false

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
            NSLog("[GlossyGlass] Loader v4 bootstrap")
        }

        // Immediate path — do not block on gate
        DispatchQueue.main.async {
            self.startCore(reason: "immediate")
        }

        for delay in [0.4, 1.0, 2.0, 4.0, 7.0, 12.0, 20.0, 35.0] as [TimeInterval] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.startCore(reason: "retry-\(delay)")
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
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                GlassAppSupport.shared.refreshDetection()
                self.startCore(reason: name.rawValue)
            }
        }
    }

    private func startCore(reason: String) {
        if GlassPreferences.shared.safeMode {
            NSLog("[GlossyGlass] safe mode skip \(reason)")
            return
        }
        GlassAppSupport.shared.refreshDetection()
        armObserversIfNeeded()

        // Always try inject + chrome without waiting
        GlassDeviceProfiler.applyIfNeeded()
        GlassInjector.start()
        GlassStyleApplicator.start()
        GlassScreenProfileMonitor.start()

        // Welcome as soon as any window exists
        showWelcomeIfPossible()

        // Also schedule through ready gate for late LC UI
        GlassReadyGate.shared.waitUntilReady {
            GlassInjector.start()
            GlassStyleApplicator.applyAll()
            self.showWelcomeIfPossible()
        }

        NSLog("[GlossyGlass] startCore \(reason) ig=%d windows=%d",
              GlassAppSupport.shared.isInstagram ? 1 : 0,
              GlassAppSupport.allWindows().count)
    }

    private func showWelcomeIfPossible() {
        guard !GlassLoader.welcomeShown else { return }
        let windows = GlassAppSupport.allWindows()
        guard !windows.isEmpty else { return }
        GlassLoader.welcomeShown = true
        GlassWelcome.present(force: true)
    }
}

private enum GlassLoadTrigger {
    static let arm: Void = {
        DispatchQueue.main.async { _ = GlassLoader.shared }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            GlassLoader.kick(reason: "LoadTrigger+1s")
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
