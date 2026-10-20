import UIKit

@objc public final class GlassReady: NSObject {
    @objc public static let shared = GlassReady()
    private var isReady = false
    private var callbacks: [() -> Void] = []

    @objc public func waitUntilReady(_ completion: @escaping () -> Void) {
        if isReady { completion(); return }
        callbacks.append(completion)
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            attempts += 1
            if self.check() || attempts >= 50 {
                t.invalidate()
                self.isReady = true
                let cbs = self.callbacks
                self.callbacks.removeAll()
                cbs.forEach { $0() }
            }
        }
    }

    private func check() -> Bool {
        guard let w = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
              let root = w.rootViewController else { return false }
        return root.view.bounds.width > 100 && !root.view.subviews.isEmpty
    }
}
