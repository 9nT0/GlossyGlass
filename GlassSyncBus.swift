import Foundation

/// Single notification bus so prefs / chrome / injection stay in sync
@objc public class GlassSyncBus: NSObject {
    @objc public static let shared = GlassSyncBus()

    @objc public static let didSync = Notification.Name("GlassSyncBusDidSync")

    private var pending = false

    @objc public func requestSync(reason: String) {
        if pending { return }
        pending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.pending = false
            GlassPreferences.shared.log("Sync: \(reason)")
            NotificationCenter.default.post(name: .glassPreferencesDidChange, object: nil)
            GlassStyleApplicator.applyAll()
            NotificationCenter.default.post(name: GlassSyncBus.didSync, object: nil, userInfo: ["reason": reason])
        }
    }
}
