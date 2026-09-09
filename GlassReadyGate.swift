import UIKit

/// Waits until the guest UI is actually alive before injection (critical for Live Container).
@objc public class GlassReadyGate: NSObject {

    @objc public static let shared = GlassReadyGate()

    private var polling = false
    private var startedAt: Date?

    /// True when we have a usable window + (IG signals OR any root VC / tab bar).
    @objc public func isUIReady() -> Bool {
        let windows = GlassAppSupport.allWindows()
        guard !windows.isEmpty else { return false }

        let hasKeyOrLarge = windows.contains { $0.isKeyWindow || ($0.bounds.width > 100 && $0.rootViewController != nil) }
        guard hasKeyOrLarge else { return false }

        // Instagram guest signals
        if GlassAppSupport.shared.isInstagram { return true }

        // Any substantial hierarchy
        for w in windows {
            if w.rootViewController != nil { return true }
            if findTabBar(in: w) != nil { return true }
        }
        return false
    }

    /// Poll until ready, then run `onReady`. Container mode: up to 60s. Else 30s.
    @objc public func waitUntilReady(onReady: @escaping () -> Void) {
        GlassAppSupport.shared.refreshDetection()

        if isUIReady() {
            onReady()
            return
        }

        if polling {
            // Already waiting — still try onReady when current poll succeeds via shared flag
            return
        }

        polling = true
        startedAt = Date()
        let limit: TimeInterval = GlassAppSupport.shared.isContainerEnvironment ? 60.0 : 30.0
        let interval: TimeInterval = 0.5

        func tick() {
            GlassAppSupport.shared.refreshDetection()
            if isUIReady() {
                polling = false
                NSLog("[GlossyGlass] ReadyGate: UI ready (%.1fs)", Date().timeIntervalSince(startedAt ?? Date()))
                onReady()
                return
            }
            let elapsed = Date().timeIntervalSince(startedAt ?? Date())
            if elapsed >= limit {
                polling = false
                NSLog("[GlossyGlass] ReadyGate: timeout after %.0fs — proceeding anyway", elapsed)
                onReady()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                tick()
            }
        }

        NSLog("[GlossyGlass] ReadyGate: waiting for UI (container=%@)", GlassAppSupport.shared.isContainerEnvironment ? "yes" : "no")
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            tick()
        }
    }

    private func findTabBar(in view: UIView) -> UITabBar? {
        if let t = view as? UITabBar { return t }
        for s in view.subviews {
            if let t = findTabBar(in: s) { return t }
        }
        return nil
    }
}
