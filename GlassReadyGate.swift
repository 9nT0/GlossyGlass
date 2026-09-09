import UIKit

/// Waits until guest UI is alive before injection (critical for Live Container).
/// Supports multiple concurrent waiters — LC + DylibLoader kick many times.
@objc public class GlassReadyGate: NSObject {

    @objc public static let shared = GlassReadyGate()

    private var polling = false
    private var startedAt: Date?
    private var waiters: [() -> Void] = []
    private var alreadyReady = false

    /// True when we have a usable window + (IG signals OR any root VC / tab bar).
    @objc public func isUIReady() -> Bool {
        let windows = GlassAppSupport.allWindows()
        guard !windows.isEmpty else { return false }

        let hasKeyOrLarge = windows.contains {
            $0.isKeyWindow || ($0.bounds.width > 100 && $0.rootViewController != nil)
        }
        guard hasKeyOrLarge else { return false }

        if GlassAppSupport.shared.isInstagram { return true }

        for w in windows {
            if w.rootViewController != nil { return true }
            if findTabBar(in: w) != nil { return true }
            if GlassAppSupport.shared.isContainerEnvironment,
               w.bounds.width > 100, w.alpha > 0.5, !w.subviews.isEmpty {
                return true
            }
        }
        return false
    }

    /// Poll until ready, then run `onReady`. Multiple callers are all notified.
    @objc public func waitUntilReady(onReady: @escaping () -> Void) {
        GlassAppSupport.shared.refreshDetection()

        if alreadyReady || isUIReady() {
            alreadyReady = true
            DispatchQueue.main.async { onReady() }
            return
        }

        waiters.append(onReady)
        if polling { return }

        polling = true
        startedAt = Date()
        let limit: TimeInterval = GlassAppSupport.shared.isContainerEnvironment ? 60.0 : 30.0
        let interval: TimeInterval = GlassAppSupport.shared.isContainerEnvironment ? 0.4 : 0.5

        func tick() {
            GlassAppSupport.shared.refreshDetection()
            if isUIReady() {
                finishReady(tag: "ready")
                return
            }
            let elapsed = Date().timeIntervalSince(startedAt ?? Date())
            if elapsed >= limit {
                NSLog("[GlossyGlass] ReadyGate: timeout after %.0fs — proceeding", elapsed)
                finishReady(tag: "timeout")
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) { tick() }
        }

        NSLog("[GlossyGlass] ReadyGate: waiting (container=%@)",
              GlassAppSupport.shared.isContainerEnvironment ? "yes" : "no")
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { tick() }
    }

    private func finishReady(tag: String) {
        polling = false
        alreadyReady = true
        let copy = waiters
        waiters.removeAll()
        NSLog("[GlossyGlass] ReadyGate: %@ — notifying %lu waiters",
              tag, UInt(copy.count))
        for w in copy { w() }
    }

    @objc public func resetForRetry() {
        alreadyReady = false
        polling = false
        waiters.removeAll()
    }

    private func findTabBar(in view: UIView) -> UITabBar? {
        if let t = view as? UITabBar { return t }
        for s in view.subviews {
            if let t = findTabBar(in: s) { return t }
        }
        return nil
    }
}
