import UIKit

/// Waits until guest UI is alive. Supports multiple waiters (critical fix).
@objc public class GlassReadyGate: NSObject {

    @objc public static let shared = GlassReadyGate()

    private var polling = false
    private var startedAt: Date?
    private var waiters: [() -> Void] = []
    private var alreadyReady = false

    @objc public func isUIReady() -> Bool {
        let windows = GlassAppSupport.allWindows()
        if windows.isEmpty { return false }
        let hasWindow = windows.contains {
            $0.isKeyWindow || ($0.bounds.width > 50 && $0.rootViewController != nil) || !$0.subviews.isEmpty
        }
        return hasWindow
    }

    @objc public func waitUntilReady(onReady: @escaping () -> Void) {
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

        func tick() {
            if isUIReady() {
                finishReady()
                return
            }
            let elapsed = Date().timeIntervalSince(startedAt ?? Date())
            if elapsed >= limit {
                NSLog("[GlossyGlass] ReadyGate timeout — proceed")
                finishReady()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { tick() }
        }
        NSLog("[GlossyGlass] ReadyGate waiting…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { tick() }
    }

    private func finishReady() {
        polling = false
        alreadyReady = true
        let copy = waiters
        waiters.removeAll()
        for w in copy {
            w()
        }
    }
}
