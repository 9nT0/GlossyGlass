import UIKit

/// Softens system context menus only — never paints content or stacks effect views.
@objc public final class GlassContextChrome: NSObject {

    @objc public static let shared = GlassContextChrome()
    private var observer: NSObjectProtocol?
    private var timer: Timer?

    private override init() { super.init() }

    @objc public func start() {
        DispatchQueue.main.async {
            if self.observer == nil {
                self.observer = NotificationCenter.default.addObserver(
                    forName: UIWindow.didBecomeVisibleNotification,
                    object: nil, queue: .main
                ) { [weak self] _ in self?.scan() }
            }
            self.timer?.invalidate()
            // Rare scan — avoid hitch
            self.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                self?.scan()
            }
        }
    }

    @objc public func scan() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        // Only sweep bad overlays — do not install new full plates on random views
        GlassOverlayRegistry.shared.sweepContentOverlays()
    }
}
