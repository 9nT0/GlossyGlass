import UIKit

/// GlossyGlass v3 injector
/// - Single host lock (only one Glass button)
/// - Overcrowding protection
/// - Profile/Action container bias
/// - Hide button actually removes existing buttons
/// - Attempts reset when app becomes active
@objc public class GlassInjector: NSObject {

    private static var observer: NSObjectProtocol?
    private static var hasStarted = false
    private static var injectionAttempts = 0
    private static let maxAttempts = 14
    private static weak var attachedButton: GlassSettingsButton?
    private static weak var attachedHost: UIView?

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
                // Reset attempts when coming back to foreground
                injectionAttempts = 0
                attemptInjection()
            }

            let delays: [TimeInterval] = [0.6, 1.2, 2.0, 3.5, 5.5, 8.0, 11.0, 15.0]
            for delay in delays {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    attemptInjection()
                }
            }

            GlassPreferences.shared.log("GlassInjector started (v3)")
        }
    }


    @objc public static func forceRedetect() {
        injectionAttempts = 0
        attachedButton = nil
        attachedHost = nil
        removeExistingButtons()
        attemptInjection()
    }

    @objc public static func attemptInjection() {
        let prefs = GlassPreferences.shared
        if prefs.safeMode {
            removeExistingButtons()
            GlassDiagnostics.shared.recordInjection(score: 0, host: "none", candidates: 0, attached: false, note: "Safe mode active")
            return
        }
        guard prefs.isEnabled else { return }

        if prefs.hideGlassButton {
            removeExistingButtons()
            attachedButton = nil
            attachedHost = nil
            return
        }

        // Already attached and still in hierarchy → done
        if let btn = attachedButton, btn.superview != nil {
            return
        }

        injectionAttempts += 1
        if injectionAttempts > maxAttempts { return }

        var best: (stack: UIStackView, score: Int)?

        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where !window.isHidden {
                collectCandidates(in: window, depth: 0, best: &best)
            }
        }

        guard let winner = best, winner.score >= 40 else {
            prefs.log("No suitable host (best score: \(best?.score ?? 0))")
            return
        }

        // Remove any stray buttons first
        removeExistingButtons()

        let btn = GlassSettingsButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 32).isActive = true
        winner.stack.addArrangedSubview(btn)

        attachedButton = btn
        attachedHost = winner.stack
        let hostName = NSStringFromClass(type(of: winner.stack))
        GlassDiagnostics.shared.recordInjection(
            score: winner.score,
            host: hostName,
            candidates: 1,
            attached: true,
            note: "Injected successfully"
        )
        prefs.log("Injected Glass button (score \(winner.score))")
    }

    // MARK: - Candidate scoring

    private static func collectCandidates(in view: UIView, depth: Int, best: inout (stack: UIStackView, score: Int)?) {
        guard depth < 16 else { return }

        if let stack = view as? UIStackView,
           stack.axis == .horizontal,
           stack.arrangedSubviews.count >= 2,
           stack.arrangedSubviews.count <= 6 {

            let score = scoreStack(stack, container: view.superview)
            if score >= 40 {
                if best == nil || score > best!.score {
                    best = (stack, score)
                }
            }
        }

        // Bias: containers whose class name suggests profile actions
        let className = NSStringFromClass(type(of: view))
        if className.contains("Profile") || className.contains("Action") || className.contains("ButtonBar") {
            if let stack = firstHorizontalStack(in: view) {
                let score = scoreStack(stack, container: view) + 25
                if score >= 40 {
                    if best == nil || score > best!.score {
                        best = (stack, score)
                    }
                }
            }
        }

        for sub in view.subviews {
            collectCandidates(in: sub, depth: depth + 1, best: &best)
        }
    }

    private static func scoreStack(_ stack: UIStackView, container: UIView?) -> Int {
        // Already has our button
        if stack.arrangedSubviews.contains(where: { $0 is GlassSettingsButton }) {
            return -100
        }

        let controls = stack.arrangedSubviews.filter { v in
            v is UIButton || v is UIControl ||
            NSStringFromClass(type(of: v)).lowercased().contains("button")
        }

        let count = controls.count
        guard count >= 2, count <= 5 else { return 0 }

        var score = 20
        score += min(count, 4) * 8          // prefer 3–4 buttons
        if stack.arrangedSubviews.count <= 5 { score += 10 }
        if stack.spacing > 0 && stack.spacing < 20 { score += 5 }

        // Prefer stacks that look like action bars (similar heights)
        let heights = controls.map { $0.bounds.height }.filter { $0 > 0 }
        if heights.count >= 2 {
            let avg = heights.reduce(0, +) / CGFloat(heights.count)
            if heights.allSatisfy({ abs($0 - avg) < 8 }) { score += 15 }
        }

        // Penalty: likely nav/tab
        let containerName = container.map { NSStringFromClass(type(of: $0)) } ?? ""
        if containerName.contains("Navigation") || containerName.contains("TabBar") {
            score -= 40
        }

        return score
    }

    private static func firstHorizontalStack(in view: UIView) -> UIStackView? {
        if let s = view as? UIStackView, s.axis == .horizontal { return s }
        for sub in view.subviews {
            if let found = firstHorizontalStack(in: sub) { return found }
        }
        return nil
    }

    // MARK: - Cleanup

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
            } else {
                removeButtons(in: sub)
            }
        }
        if let stack = view as? UIStackView {
            for v in stack.arrangedSubviews where v is GlassSettingsButton {
                stack.removeArrangedSubview(v)
                v.removeFromSuperview()
            }
        }
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
            if GlassPreferences.shared.hapticsEnabled {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            }
        case .ended, .cancelled, .failed:
            GlassAnimations.longPressRelease(view)
        default:
            break
        }
    }
}
