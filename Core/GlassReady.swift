import UIKit

@objc public final class GlassReady: NSObject {
    @objc public static let shared = GlassReady()
    private var ready = false
    private var cbs: [() -> Void] = []

    @objc public func waitUntilReady(_ completion: @escaping () -> Void) {
        if ready { completion(); return }
        cbs.append(completion)
        var n = 0
        Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            n += 1
            if self.check() || n >= 55 {
                t.invalidate()
                self.ready = true
                let c = self.cbs
                self.cbs.removeAll()
                c.forEach { $0() }
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
