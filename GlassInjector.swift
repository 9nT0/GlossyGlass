import UIKit

/// GlossyGlass v3.6 injector
/// - Instagram-first detection, generic fallback
/// - 3s hold on Messages control opens settings (not profile, not anywhere)
/// - Soft retries + last-good-host memory
@objc public class GlassInjector: NSObject {

    private static var observer: NSObjectProtocol?
    private static var hasStarted = false
    private static var injectionAttempts = 0
    private static weak var attachedButton: GlassSettingsButton?
    private static weak var attachedHost: UIView?
    private static weak var lastGoodHost: UIView?
    private static var revalidateTimer: Timer?
    private static var messagesPressCount = 0

    @objc public static func start() {
        DispatchQueue.main.async {
            if !hasStarted {
                hasStarted = true
                injectionAttempts = 0

                observer = NotificationCenter.default.addObserver(
                    forName: UIApplication.didBecomeActiveNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    injectionAttempts = max(0, injectionAttempts - 6)
                    attemptInjection()
                    installMessagesLongPress()
                }

                revalidateTimer?.invalidate()
                revalidateTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                    revalidateAttachment()
                    installMessagesLongPress()
                }

                GlassDeviceProfiler.applyIfNeeded()
            }

            // Faster early attempts for IG
            let delays: [TimeInterval] = GlassAppSupport.shared.isInstagram
                ? [0.2, 0.5, 0.9, 1.4, 2.0, 3.0, 4.5, 6.5, 9.0, 12.0, 18.0, 25.0]
                : [0.5, 1.2, 2.5, 4.0, 7.0, 11.0, 16.0, 24.0]

            for delay in delays {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    attemptInjection()
                    installMessagesLongPress()
                }
            }

            attemptInjection()
            installMessagesLongPress()
            GlassPreferences.shared.log("Injector v3.6 host=\(GlassAppSupport.shared.bundleId)")
        }
    }

    @objc public static func forceRedetect() {
        injectionAttempts = 0
        attachedButton = nil
        attachedHost = nil
        // keep lastGoodHost as hint
        removeExistingButtons()
        attemptInjection()
        installMessagesLongPress()
    }

    @objc public static func resetInjectionState() {
        injectionAttempts = 0
        attachedButton = nil
        attachedHost = nil
        lastGoodHost = nil
        removeExistingButtons()
        attemptInjection()
    }

    // MARK: - Messages-only 3s hold

    private static func installMessagesLongPress() {
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            for window in ws.windows where !window.isHidden {
                attachMessagesPress(in: window, depth: 0)
            }
        }
    }

    private static func attachMessagesPress(in view: UIView, depth: Int) {
        guard depth < 18 else { return }
        let name = NSStringFromClass(type(of: view)).lowercased()

        // Messages / Direct / Inbox targets only (NOT profile, NOT global)
        let isMessages =
            name.contains("direct") ||
            name.contains("message") ||
            name.contains("inbox") ||
            name.contains("messenger") ||
            name.contains("dmtab") ||
            name.contains("chat")

        // Tab bar item that looks like messages (accessibility label)
        var labelHit = false
        if let lab = view.accessibilityLabel?.lowercased() {
            labelHit = lab.contains("message") || lab.contains("direct") || lab.contains("inbox")
        }

        let isControl = view is UIControl || view is UIButton
        if (isMessages || labelHit) && isControl {
            let exists = view.gestureRecognizers?.contains { $0 is GlassOpenSettingsLongPress } ?? false
            if !exists {
                let g = GlassOpenSettingsLongPress()
                g.cancelsTouchesInView = false
                g.delegate = GlassGestureDelegate.shared
                view.addGestureRecognizer(g)
                messagesPressCount += 1
            }
        }

        // Glass button itself: 3s also opens (tap still opens)
        if view is GlassSettingsButton {
            let exists = view.gestureRecognizers?.contains { $0 is GlassOpenSettingsLongPress } ?? false
            if !exists {
                let g = GlassOpenSettingsLongPress()
                g.cancelsTouchesInView = false
                view.addGestureRecognizer(g)
            }
        }

        for sub in view.subviews {
            attachMessagesPress(in: sub, depth: depth + 1)
        }
    }

    private static func revalidateAttachment() {
        let prefs = GlassPreferences.shared
        if prefs.safeMode || prefs.hideGlassButton {
            if attachedButton != nil {
                removeExistingButtons()
                attachedButton = nil
                attachedHost = nil
            }
            return
        }
        guard prefs.isEnabled else { return }

        if attachedButton == nil || attachedButton?.superview == nil {
            attachedButton = nil
            attachedHost = nil
            if injectionAttempts > 10 { injectionAttempts = 5 }
            attemptInjection()
        }

        // Warn generic apps after sustained failure
        if injectionAttempts >= 12 && !GlassDiagnostics.shared.isAttached {
            GlassAppSupport.shared.warnIfUnsupportedIfNeeded()
        }
    }

    @objc public static func attemptInjection() {
        let prefs = GlassPreferences.shared

        if prefs.safeMode {
            removeExistingButtons()
            attachedButton = nil
            attachedHost = nil
            GlassDiagnostics.shared.recordInjection(score: 0, host: "none", candidates: 0, attached: false, note: "Safe mode")
            return
        }
        guard prefs.isEnabled else { return }

        if prefs.hideGlassButton {
            removeExistingButtons()
            attachedButton = nil
            attachedHost = nil
            return
        }

        if let btn = attachedButton, btn.superview != nil { return }

        // Try last good host first (fast path)
        if let host = lastGoodHost, host.superview != nil {
            if let stack = host as? UIStackView,
               !stack.arrangedSubviews.contains(where: { $0 is GlassSettingsButton }) {
                inject(into: stack, kind: "LastGood", score: 90)
                return
            }
        }

        injectionAttempts += 1
        if injectionAttempts > 40 && injectionAttempts % 6 != 0 { return }

        var best: (view: UIView, score: Int, kind: String)?
        var candidateCount = 0
        let igBoost = GlassAppSupport.shared.isInstagram

        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where !window.isHidden {
                scan(window, depth: 0, best: &best, count: &candidateCount, igBoost: igBoost)
            }
        }

        guard let winner = best, winner.score >= (igBoost ? 32 : 38) else {
            GlassDiagnostics.shared.recordInjection(
                score: best?.score ?? 0,
                host: best?.kind ?? "none",
                candidates: candidateCount,
                attached: false,
                note: "No host (attempt \(injectionAttempts))"
            )
            if injectionAttempts >= 14 {
                GlassAppSupport.shared.warnIfUnsupportedIfNeeded()
            }
            return
        }

        inject(into: winner.view, kind: winner.kind, score: winner.score)
    }

    private static func inject(into host: UIView, kind: String, score: Int) {
        removeExistingButtons()
        let btn = GlassSettingsButton()
        btn.translatesAutoresizingMaskIntoConstraints = false

        if let stack = host as? UIStackView {
            let heights = stack.arrangedSubviews.compactMap { v -> CGFloat? in
                let h = v.bounds.height
                return (h > 18 && h < 56) ? h : nil
            }
            let h: CGFloat = heights.isEmpty ? 32 : heights.reduce(0, +) / CGFloat(heights.count)
            btn.heightAnchor.constraint(equalToConstant: h).isActive = true
            stack.addArrangedSubview(btn)
        } else {
            host.addSubview(btn)
            NSLayoutConstraint.activate([
                btn.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -12),
                btn.topAnchor.constraint(equalTo: host.topAnchor, constant: 8),
                btn.heightAnchor.constraint(equalToConstant: 32),
                btn.widthAnchor.constraint(greaterThanOrEqualToConstant: 56)
            ])
        }

        let hold = GlassOpenSettingsLongPress()
        hold.cancelsTouchesInView = false
        btn.addGestureRecognizer(hold)

        attachedButton = btn
        attachedHost = host
        lastGoodHost = host
        GlassDiagnostics.shared.recordInjection(
            score: score, host: kind, candidates: 1, attached: true, note: "Injected via \(kind)"
        )
        GlassPreferences.shared.log("Injected \(kind) score=\(score)")
    }

    // MARK: - Scan

    private static func scan(_ view: UIView, depth: Int, best: inout (view: UIView, score: Int, kind: String)?, count: inout Int, igBoost: Bool) {
        guard depth < 20 else { return }
        let name = NSStringFromClass(type(of: view))

        if let stack = view as? UIStackView, stack.axis == .horizontal {
            var s = scoreStack(stack, container: view.superview)
            if igBoost && (name.contains("Profile") || name.contains("Action") || (view.superview.map { NSStringFromClass(type(of: $0)) } ?? "").contains("Profile")) {
                s += 20
            }
            if s >= 28 {
                count += 1
                if s >= 32, best == nil || s > best!.score { best = (stack, s, "Stack") }
            }
        }

        let buttons = view.subviews.filter { $0 is UIButton || $0 is UIControl }
        if buttons.count >= 2 && buttons.count <= 6 {
            var s = scoreButtonRow(buttons, in: view)
            if igBoost { s += 8 }
            if s >= 30 {
                count += 1
                if s >= 38, best == nil || s > best!.score {
                    if let stack = view as? UIStackView {
                        best = (stack, s, "Row-Stack")
                    } else if let stack = view.subviews.compactMap({ $0 as? UIStackView }).first(where: { $0.axis == .horizontal }) {
                        best = (stack, s + 5, "Row-Inner")
                    } else {
                        best = (view, s, "Row-Box")
                    }
                }
            }
        }

        // IG-oriented hints first
        let igHints = ["Profile", "Action", "ButtonBar", "EditProfile", "UserDetail", "Header"]
        let genericHints = ["Toolbar", "Header", "Action", "NavBar", "TopBar"]
        let hints = igBoost ? igHints : genericHints
        if hints.contains(where: { name.contains($0) }) {
            if let stack = firstHorizontalStack(in: view) {
                let s = scoreStack(stack, container: view) + (igBoost ? 40 : 25)
                count += 1
                if s >= 32, best == nil || s > best!.score {
                    best = (stack, s, "Hint-\(name)")
                }
            }
        }

        for sub in view.subviews {
            scan(sub, depth: depth + 1, best: &best, count: &count, igBoost: igBoost)
        }
    }

    private static func scoreStack(_ stack: UIStackView, container: UIView?) -> Int {
        if stack.arrangedSubviews.contains(where: { $0 is GlassSettingsButton }) { return -100 }
        let controls = stack.arrangedSubviews.filter {
            $0 is UIButton || $0 is UIControl ||
            NSStringFromClass(type(of: $0)).lowercased().contains("button")
        }
        guard controls.count >= 2, controls.count <= 5 else { return 0 }
        var score = 25 + min(controls.count, 4) * 8
        if stack.arrangedSubviews.count <= 5 { score += 8 }
        let heights = controls.map { $0.bounds.height }.filter { $0 > 0 }
        if heights.count >= 2 {
            let avg = heights.reduce(0, +) / CGFloat(heights.count)
            if heights.allSatisfy({ abs($0 - avg) < 12 }) { score += 12 }
        }
        let cname = container.map { NSStringFromClass(type(of: $0)) } ?? ""
        if cname.contains("Navigation") || cname.contains("TabBar") { score -= 50 }
        if cname.contains("Profile") || cname.contains("Action") { score += 25 }
        return score
    }

    private static func scoreButtonRow(_ buttons: [UIView], in container: UIView) -> Int {
        let mids = buttons.map { $0.frame.midY }
        guard let first = mids.first else { return 0 }
        guard mids.allSatisfy({ abs($0 - first) < 16 }) else { return 10 }
        var score = 30 + buttons.count * 5
        let cname = NSStringFromClass(type(of: container))
        if cname.contains("Profile") || cname.contains("Action") { score += 25 }
        if cname.contains("Navigation") || cname.contains("TabBar") { score -= 40 }
        return score
    }

    private static func firstHorizontalStack(in view: UIView) -> UIStackView? {
        if let s = view as? UIStackView, s.axis == .horizontal { return s }
        for sub in view.subviews {
            if let f = firstHorizontalStack(in: sub) { return f }
        }
        return nil
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

private class GlassOpenSettingsLongPress: UILongPressGestureRecognizer {
    init() {
        super.init(target: nil, action: nil)
        minimumPressDuration = 3.0
        cancelsTouchesInView = false
        numberOfTouchesRequired = 1
        addTarget(self, action: #selector(handle))
    }

    @objc private func handle(_ g: UILongPressGestureRecognizer) {
        guard g.state == .began else { return }
        if GlassPreferences.shared.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        GlassSettingsPresenter.present()
    }
}

private class GlassGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = GlassGestureDelegate()
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

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
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        case .ended, .cancelled, .failed:
            GlassAnimations.longPressRelease(view)
        default: break
        }
    }
}
