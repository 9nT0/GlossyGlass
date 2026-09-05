import UIKit

/// Much stronger injector with multiple detection strategies, better timing, and long-press support.
@objc public class GlassInjector: NSObject {

    private static var observer: NSObjectProtocol?
    private static var hasStarted = false
    private static var injectedButtons = NSHashTable<UIView>.weakObjects()

    @objc public static func start() {
        DispatchQueue.main.async {
            guard !hasStarted else { return }
            hasStarted = true

            observer = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                attemptInjection()
            }

            // Aggressive retry schedule
            let delays: [TimeInterval] = [0.8, 1.6, 2.8, 4.5, 7.0, 11.0, 16.0]
            for delay in delays {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    attemptInjection()
                }
            }

            // Also watch for significant view changes
            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    attemptInjection()
                }
            }

            GlassPreferences.shared.log("GlassInjector v2 started")
        }
    }

    @objc public static func attemptInjection() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled else { return }

        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where !window.isHidden {
                searchAndInject(in: window, depth: 0)
            }
        }
    }

    private static func searchAndInject(in view: UIView, depth: Int) {
        guard depth < 18 else { return } // safety

        // Strategy 1: Horizontal UIStackView with multiple buttons
        if let stack = view as? UIStackView,
           stack.axis == .horizontal,
           stack.arrangedSubviews.count >= 2,
           stack.arrangedSubviews.count <= 8 {

            let buttonLike = stack.arrangedSubviews.filter {
                $0 is UIButton || $0 is UIControl || String(describing: type(of: $0)).lowercased().contains("button")
            }

            if buttonLike.count >= 2 {
                tryInject(into: stack)
            }
        }

        // Strategy 2: UIView that contains several UIButtons side by side
        let buttons = view.subviews.filter { $0 is UIButton }
        if buttons.count >= 3 && buttons.count <= 7 {
            // Check if they are roughly on the same horizontal line
            let ys = buttons.map { $0.frame.midY }
            if let minY = ys.min(), let maxY = ys.max(), abs(maxY - minY) < 40 {
                tryInjectNear(buttons: buttons, in: view)
            }
        }

        for sub in view.subviews {
            searchAndInject(in: sub, depth: depth + 1)
        }
    }

    private static func tryInject(into stack: UIStackView) {
        let prefs = GlassPreferences.shared
        guard prefs.showGlassButton else { return }

        // Already injected?
        if stack.arrangedSubviews.contains(where: { $0 is GlassSettingsButton }) { return }

        // Only inject if there is reasonable space (not already too crowded)
        guard stack.arrangedSubviews.count < 6 else {
            prefs.log("Stack already has \(stack.arrangedSubviews.count) items – skipping to avoid overcrowding")
            return
        }

        let btn = GlassSettingsButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 32).isActive = true
        stack.addArrangedSubview(btn)
        injectedButtons.add(btn)
        prefs.log("Injected Glass button into stack (now \(stack.arrangedSubviews.count) items)")
    }

    private static func tryInjectNear(buttons: [UIView], in parent: UIView) {
        let prefs = GlassPreferences.shared
        guard prefs.showGlassButton else { return }
        if parent.subviews.contains(where: { $0 is GlassSettingsButton }) { return }

        let btn = GlassSettingsButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(btn)

        // Place to the right of the last button
        if let last = buttons.sorted(by: { $0.frame.maxX < $1.frame.maxX }).last {
            NSLayoutConstraint.activate([
                btn.centerYAnchor.constraint(equalTo: last.centerYAnchor),
                btn.leadingAnchor.constraint(equalTo: last.trailingAnchor, constant: 8),
                btn.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
        injectedButtons.add(btn)
        prefs.log("Injected Glass button near existing buttons")
    }
}

// MARK: - Long press helper (improved)

@objc public class GlassLongPress: NSObject {

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

    @objc private func handle(_ g: UILongPressGestureRecognizer) {
        guard let view = g.view else { return }
        switch g.state {
        case .began:
            GlassAnimations.longPressLift(view)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .ended, .cancelled, .failed:
            GlassAnimations.longPressRelease(view)
        default: break
        }
    }
}
