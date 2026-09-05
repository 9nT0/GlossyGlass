import UIKit

/// Improved injector for v2.1
/// - Better timing / retries
/// - Overcrowding protection
/// - Respects hideGlassButton preference
@objc public class GlassInjector: NSObject {

    private static var observer: NSObjectProtocol?
    private static var hasStarted = false
    private static var injectionAttempts = 0
    private static let maxAttempts = 12

    @objc public static func start() {
        DispatchQueue.main.async {
            guard !hasStarted else { return }
            hasStarted = true
            injectionAttempts = 0

            observer = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                attemptInjection()
            }

            // More aggressive retry schedule for late-loading UIs
            let delays: [TimeInterval] = [0.8, 1.5, 2.5, 4.0, 6.0, 9.0, 12.0, 16.0]
            for delay in delays {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    attemptInjection()
                }
            }

            GlassPreferences.shared.log("GlassInjector started (v2.1)")
        }
    }

    @objc public static func attemptInjection() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled else { return }

        // User chose to hide the button
        if prefs.hideGlassButton {
            removeExistingButtons()
            return
        }

        injectionAttempts += 1
        if injectionAttempts > maxAttempts { return }

        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where !window.isHidden {
                searchAndInject(in: window, depth: 0)
            }
        }
    }

    private static func removeExistingButtons() {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                removeButtons(in: window)
            }
        }
    }

    private static func removeButtons(in view: UIView) {
        for sub in view.subviews {
            if let btn = sub as? GlassSettingsButton {
                btn.removeFromSuperview()
            }
            removeButtons(in: sub)
        }
        if let stack = view as? UIStackView {
            stack.arrangedSubviews.forEach { v in
                if v is GlassSettingsButton {
                    stack.removeArrangedSubview(v)
                    v.removeFromSuperview()
                }
            }
        }
    }

    private static func searchAndInject(in view: UIView, depth: Int) {
        // Safety: limit recursion
        guard depth < 18 else { return }

        // Strategy 1: Horizontal UIStackView with existing buttons
        if let stack = view as? UIStackView,
           stack.axis == .horizontal,
           stack.arrangedSubviews.count >= 2,
           stack.arrangedSubviews.count <= 6 {

            let alreadyHas = stack.arrangedSubviews.contains { $0 is GlassSettingsButton }
            if !alreadyHas {
                // Overcrowding protection: only add if there's room
                let buttonCount = stack.arrangedSubviews.filter { $0 is UIButton || $0 is UIControl }.count
                if buttonCount >= 2 && buttonCount <= 5 {
                    let btn = GlassSettingsButton()
                    btn.translatesAutoresizingMaskIntoConstraints = false
                    btn.heightAnchor.constraint(equalToConstant: 32).isActive = true
                    stack.addArrangedSubview(btn)
                    GlassPreferences.shared.log("Injected into stack (buttons: \(buttonCount + 1))")
                }
            }
        }

        // Strategy 2: Look for common profile action containers
        let className = NSStringFromClass(type(of: view))
        if className.contains("Profile") || className.contains("Action") || className.contains("ButtonBar") {
            if let stack = findHorizontalStack(in: view),
               !stack.arrangedSubviews.contains(where: { $0 is GlassSettingsButton }),
               stack.arrangedSubviews.count >= 2,
               stack.arrangedSubviews.count <= 5 {
                let btn = GlassSettingsButton()
                btn.translatesAutoresizingMaskIntoConstraints = false
                btn.heightAnchor.constraint(equalToConstant: 32).isActive = true
                stack.addArrangedSubview(btn)
                GlassPreferences.shared.log("Injected via profile/action container")
            }
        }

        for sub in view.subviews {
            searchAndInject(in: sub, depth: depth + 1)
        }
    }

    private static func findHorizontalStack(in view: UIView) -> UIStackView? {
        if let stack = view as? UIStackView, stack.axis == .horizontal {
            return stack
        }
        for sub in view.subviews {
            if let found = findHorizontalStack(in: sub) {
                return found
            }
        }
        return nil
    }
}

// MARK: - Long press helper

@objc public class GlassLongPress: NSObject {

    @objc public static func enable(on view: UIView) {
        let already = view.gestureRecognizers?.contains { $0 is GlassLongPressGesture } ?? false
        guard !already else { return }
        view.addGestureRecognizer(GlassLongPressGesture())
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
