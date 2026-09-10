import Foundation

/// Single source of truth broadcast: prefs → surfaces → chrome → diag.
@objc public final class GlassSyncBus: NSObject {

    @objc public static let shared = GlassSyncBus()

    private var lastToken: UInt64 = 0

    @objc public func requestSync(reason: String = "") {
        if !reason.isEmpty {
            NSLog("[GlossyGlass] SyncBus requestSync %@", reason)
        }
        publishPreferencesChanged()
    }

    @objc public func publishPreferencesChanged() {
        lastToken &+= 1
        let token = lastToken
        DispatchQueue.main.async {
            GlassSurfaceRouter.shared.refresh()
            GlassChromeShell.shared.reassert()
            GlassStyleApplicator.applyAll()
            GlassLiquidTabBar.shared.refresh()
            NotificationCenter.default.post(
                name: .glassPreferencesDidChange,
                object: nil,
                userInfo: ["token": token]
            )
        }
    }

    @objc public func publishHierarchyChanged() {
        DispatchQueue.main.async {
            GlassSurfaceRouter.shared.refresh()
            GlassChromeShell.shared.reassert()
            GlassInjector.attemptInjection()
        }
    }

    @objc public func publishScreenChanged() {
        DispatchQueue.main.async {
            GlassSurfaceRouter.shared.refresh()
            GlassChromeShell.shared.reassert()
        }
    }
}
