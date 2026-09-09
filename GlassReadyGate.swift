import UIKit

@objc public class GlassReadyGate: NSObject {

    @objc public static let shared = GlassReadyGate()

    private var polling = false
    private var startedAt: Date?
    private var waiters: [() -> Void] = []
    private var alreadyReady = false

    @objc public func isUIReady() -> Bool {
        let windows = GlassAppSupport.allWindows()
        if windows.isEmpty {
            for scene in UIApplication.shared.connectedScenes {
                guard let ws = scene as? UIWindowScene else { continue }
                if ws.windows.contains(where: { !$0.isHidden && $0.bounds.width > 50 }) {
                    return true
                }
            }
            return false
        }

        if windows.contains(where: { $0.isKeyWindow }) { return true }
        if windows.contains(where: { $0.rootViewController != nil && $0.bounds.width > 50 }) {
            return true
        }
        if GlassAppSupport.shared.isInstagram { return true }
        if GlassAppSupport.shared.isContainerEnvironment {
            return windows.contains { $0.bounds.width > 80 && $0.alpha > 0.2 }
        }
        return windows.contains { !$0.subviews.isEmpty }
    }

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
        let limit: TimeInterval = GlassAppSupport.shared.isContainerEnvironment ? 45.0 : 20.0
        let interval: TimeInterval = 0.35

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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { tick() }
    }

    private func finishReady(tag: String) {
        polling = false
        alreadyReady = true
        let copy = waiters
        waiters.removeAll()
        NSLog("[GlossyGlass] ReadyGate: %@ — %lu waiters", tag, UInt(copy.count))
        for w in copy { w() }
    }

    @objc public func resetForRetry() {
        alreadyReady = false
        polling = false
        waiters.removeAll()
    }
}
