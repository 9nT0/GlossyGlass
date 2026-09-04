import UIKit

/// Helper that tries to place the Glass settings button next to existing tweak buttons
/// (commonly on profile screens). Fully compatible with iOS 17 – 18.x.
@objc public class GlassInjector: NSObject {

    private static var observer: NSObjectProtocol?
    private static var hasStarted = false

    /// Call once after the host app has loaded.
    /// Safe to call multiple times.
    @objc public static func start() {
        DispatchQueue.main.async {
            guard !hasStarted else { return }
            hasStarted = true

            // Observe app becoming active
            observer = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                attemptInjection()
            }

            // Multiple delayed attempts (covers different launch timings)
            let delays: [TimeInterval] = [1.0, 2.5, 5.0, 8.0]
            for delay in delays {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    attemptInjection()
                }
            }

            GlassPreferences.shared.log("GlassInjector started")
        }
    }

    @objc public static func attemptInjection() {
        guard GlassPreferences.shared.isEnabled else { return }

        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where !window.isHidden {
                searchAndInject(in: window)
            }
        }
    }

    private static func searchAndInject(in view: UIView) {
        // Look for horizontal stacks that already contain several buttons
        if let stack = view as? UIStackView,
           stack.axis == .horizontal,
           stack.arrangedSubviews.count >= 3,
           stack.arrangedSubviews.count <= 8 {

            let alreadyHas = stack.arrangedSubviews.contains { $0 is GlassSettingsButton }
            if !alreadyHas {
                let btn = GlassSettingsButton()
                btn.translatesAutoresizingMaskIntoConstraints = false
                btn.heightAnchor.constraint(equalToConstant: 32).isActive = true

                // Prefer inserting near the end (beside the last tweak button)
                stack.addArrangedSubview(btn)
                GlassPreferences.shared.log("Glass settings button injected (stack now has \(stack.arrangedSubviews.count) items)")
            }
        }

        // Limit recursion depth for safety
        for sub in view.subviews {
            searchAndInject(in: sub)
        }
    }
}

// MARK: - Long press helper for messages / cells (iOS 17–18 compatible)

@objc public class GlassLongPress: NSObject {

    /// Attach a nice modern lift effect to any view (message bubbles, cells, etc.)
    @objc public static func enable(on view: UIView) {
        let already = view.gestureRecognizers?.contains { $0 is GlassLongPressGesture } ?? false
        guard !already else { return }

        let gesture = GlassLongPressGesture()
        view.addGestureRecognizer(gesture)
    }
}

private class GlassLongPressGesture: UILongPressGestureRecognizer {

    init() {
        super.init(target: nil, action: nil)
        minimumPressDuration = 0.28
        cancelsTouchesInView = false
        addTarget(self, action: #selector(handle))
    }

    @objc private func handle(_ gesture: UILongPressGestureRecognizer) {
        guard let view = gesture.view else { return }

        switch gesture.state {
        case .began:
            GlassAnimations.longPressLift(view)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        case .ended, .cancelled, .failed:
            GlassAnimations.longPressRelease(view)
        default:
            break
        }
    }
}
