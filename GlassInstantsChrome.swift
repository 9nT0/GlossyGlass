import UIKit

/// Softens pure-black Instant / story chrome so content isn't a dead black void.
/// Does not replace Instant functionality — visual only.
@objc public final class GlassInstantsChrome: NSObject {

    @objc public static let shared = GlassInstantsChrome()
    private var timer: Timer?
    private let tag = 0x4747_494E // GGIN

    private override init() { super.init() }

    @objc public func start() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
                self?.scan()
            }
            self.scan()
        }
    }

    @objc public func scan() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        for w in GlassAppSupport.allWindows() {
            walk(w, depth: 0)
        }
    }

    private func walk(_ view: UIView, depth: Int) {
        guard depth < 14 else { return }
        let lower = NSStringFromClass(type(of: view)).lowercased()

        let isInstant =
            lower.contains("instant")
            || lower.contains("storyviewer")
            || lower.contains("storytray")
            || lower.contains("igstory")
            || lower.contains("reelstray")
            || lower.contains("sundial")

        // Full-screen near-black chrome plates
        if isInstant {
            softenBlack(view)
        }

        // Pure black full-bleed empty chrome
        if view.bounds.width > 200, view.bounds.height > 80,
           let bg = view.backgroundColor, bg.cgColor.alpha > 0.9 {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            bg.getRed(&r, green: &g, blue: &b, alpha: &a)
            if r < 0.08 && g < 0.08 && b < 0.08 && (isInstant || lower.contains("chrome") || lower.contains("header")) {
                softenBlack(view)
            }
        }

        for s in view.subviews { walk(s, depth: depth + 1) }
    }

    private func softenBlack(_ view: UIView) {
        if view.viewWithTag(tag) != nil { return }
        // Don't steal tab bars
        if view is UITabBar || view is UINavigationBar { return }

        let prefs = GlassPreferences.shared
        view.backgroundColor = UIColor.black.withAlphaComponent(0.55)

        let effect = GlassMaterialEngine.shared.blurEffect(
            style: "clear",
            dark: true,
            intensity: max(0.4, prefs.intensity * 0.7)
        )
        let blur = UIVisualEffectView(effect: effect)
        blur.tag = tag
        blur.alpha = 0.55
        blur.isUserInteractionEnabled = false
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blur, at: 0)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        for sub in view.subviews where sub.tag != tag {
            view.bringSubviewToFront(sub)
        }
    }
}
