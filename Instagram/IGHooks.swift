import UIKit

@objc public final class IGHooks: NSObject {
    @objc public static let shared = IGHooks()
    private var attached = false

    @objc public func start() {
        NotificationCenter.default.addObserver(self, selector: #selector(active), name: UIApplication.didBecomeActiveNotification, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.attach() }
    }

    @objc private func active() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { self.attach() }
    }

    private func attach() {
        guard !attached else { return }
        guard let w = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }
        let g = UILongPressGestureRecognizer(target: self, action: #selector(hold(_:)))
        g.minimumPressDuration = 1.0
        g.cancelsTouchesInView = false
        w.addGestureRecognizer(g)
        attached = true
    }

    @objc private func hold(_ g: UILongPressGestureRecognizer) {
        guard g.state == .began else { return }
        let loc = g.location(in: g.view)
        let b = g.view?.bounds ?? .zero
        if loc.y > b.height * 0.70 && loc.x > b.width * 0.52 {
            if GlassPreferences.shared.glossyMode { GlassPanelGlossy.shared.present() }
            else { GlassPanel.shared.present() }
            if GlassPreferences.shared.haptics {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
}
