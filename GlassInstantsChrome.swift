import UIKit

/// Stories / instants: do not paint glass over media. Only clear rogue GG tags.
@objc public final class GlassInstantsChrome: NSObject {
    @objc public static let shared = GlassInstantsChrome()
    private var timer: Timer?

    @objc public func start() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { [weak self] _ in
                self?.scan()
            }
        }
    }

    @objc public func scan() {
        guard GlassPreferences.shared.isEnabled, !GlassPreferences.shared.safeMode else { return }
        for w in GlassAppSupport.allWindows() {
            strip(w, depth: 0)
        }
    }

    private func strip(_ view: UIView, depth: Int) {
        guard depth < 14 else { return }
        let n = NSStringFromClass(type(of: view)).lowercased()
        let media = n.contains("story") || n.contains("reel") || n.contains("player")
            || n.contains("canvas") || n.contains("avplayer")
        if media {
            for sub in view.subviews {
                let t = sub.tag
                if t >= 0x4747_0000 && t <= 0x4747_FFFF {
                    sub.removeFromSuperview()
                }
            }
            return
        }
        for s in view.subviews { strip(s, depth: depth + 1) }
    }
}
