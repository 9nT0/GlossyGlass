import UIKit

/// GlossyGlass injector — Instagram-first, floating fallback always available.
@objc public class GlassInjector: NSObject {

    private static var hasStarted = false
    private static var injectionAttempts = 0
    private static weak var attachedButton: GlassSettingsButton?
    private static weak var attachedHost: UIView?
    private static weak var lastGoodHost: UIView?
    private static weak var floatingButton: GlassSettingsButton?
    private static var revalidateTimer: Timer?
    private static var observer: NSObjectProtocol?

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
                    GlassAppSupport.shared.refreshDetection()
                    injectionAttempts = max(0, injectionAttempts - 4)
                    attemptInjection()
                    installMessagesLongPress()
                }

                let interval: TimeInterval = GlassAppSupport.shared.isContainerEnvironment ? 1.5 : 2.5
                revalidateTimer?.invalidate()
                revalidateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                    revalidateAttachment()
                    installMessagesLongPress()
                }
            }

            GlassAppSupport.shared.refreshDetection()

            let delays: [TimeInterval]
            if GlassAppSupport.shared.isContainerEnvironment {
                delays = [0.5, 1.5, 4.0, 10.0]  // quiet bootstrap only — chrome is Coordinator
            } else if GlassAppSupport.shared.isInstagram {
                delays = [0.2, 0.5, 1.0, 2.0, 3.5, 5.0, 8.0, 12.0, 18.0]
            } else {
                delays = [0.5, 1.5, 3.0, 6.0, 12.0, 20.0]
            }

            for d in delays {
                DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                    attemptInjection()
                    installMessagesLongPress()
                }
            }
            attemptInjection()
            installMessagesLongPress()
            GlassPreferences.shared.log("Injector start host=\(GlassAppSupport.shared.bundleId)")
        }
    }

    @objc public static func forceRedetect() {
        injectionAttempts = 0
        attachedButton = nil
        attachedHost = nil
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
        removeFloatingFallback()
        attemptInjection()
    }

    // MARK: - Messages 1s hold → settings

    private static func installMessagesLongPress() {
        for window in GlassAppSupport.allWindows() {
            attachMessagesPress(in: window, depth: 0)
        }
    }

    private static func attachMessagesPress(in view: UIView, depth: Int) {
        guard depth < 16 else { return }
        let name = NSStringFromClass(type(of: view)).lowercased()
        let isMessages =
            name.contains("direct") || name.contains("message") ||
            name.contains("inbox") || name.contains("messenger") ||
            name.contains("igdirect") || name.contains("chatlist") ||
            name.contains("threadlist") || name.contains("dmtab")

        var labelHit = false
        let labels = [
            view.accessibilityLabel, view.accessibilityHint,
            (view as? UIButton)?.title(for: .normal),
            (view as? UIButton)?.currentTitle
        ].compactMap { $0?.lowercased() }
        for lab in labels {
            if lab.contains("message") || lab.contains("direct") ||
                lab.contains("inbox") || lab.contains("dm") || lab.contains("chat") {
                labelHit = true
                break
            }
        }

        let interactive = view is UIControl || view is UIButton || view.isUserInteractionEnabled
        if (isMessages || labelHit) && interactive {
            let exists = view.gestureRecognizers?.contains { $0 is GlassOpenSettingsLongPress } ?? false
            if !exists {
                let g = GlassOpenSettingsLongPress()
                g.cancelsTouchesInView = false
                g.delegate = GlassGestureDelegate.shared
                view.addGestureRecognizer(g)
            }
        }
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
        if prefs.safeMode || (prefs.hideGlassButton && !prefs.forceShowGlassButton) {
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
            if injectionAttempts > 8 { injectionAttempts = 3 }
            attemptInjection()
        }
        if injectionAttempts >= 10 && !GlassDiagnostics.shared.isAttached {
            GlassAppSupport.shared.warnIfUnsupportedIfNeeded()
        }
    }

    @objc public static func attemptInjection() {
        let prefs = GlassPreferences.shared
        if prefs.safeMode {
            removeExistingButtons()
            GlassDiagnostics.shared.recordInjection(score: 0, host: "none", candidates: 0, attached: false, note: "Safe mode")
            return
        }
        if !prefs.isEnabled {
            return
        }
        if prefs.hideGlassButton && !prefs.forceShowGlassButton {
            removeExistingButtons()
            return
        }
        if let btn = attachedButton, btn.superview != nil {
            return
        }

        injectionAttempts += 1
        GlassAppSupport.shared.refreshDetection()
        let windows = GlassAppSupport.allWindows()
        NSLog("[GlossyGlass] inject #%d win=%d ig=%d container=%d force=%d",
              injectionAttempts, windows.count,
              GlassAppSupport.shared.isInstagram ? 1 : 0,
              GlassAppSupport.shared.isContainerEnvironment ? 1 : 0,
              prefs.forceShowGlassButton ? 1 : 0)

        if prefs.forceShowGlassButton {
            ensureFloatingFallback()
            return
        }

        // Reuse last good host
        if let host = lastGoodHost, host.window != nil || host.superview != nil {
            if let stack = host as? UIStackView {
                inject(into: stack, kind: "LastGood", score: 90)
                return
            }
        }

        var best: (view: UIView, score: Int, kind: String)?
        var candidates = 0
        let igBoost = GlassAppSupport.shared.isInstagram || GlassAppSupport.shared.isContainerEnvironment

        for window in windows {
            scan(window, depth: 0, best: &best, count: &candidates, igBoost: igBoost)
        }
        if let loc = GlassLocator.shared.findBestButtonHost() {
            candidates += 1
            if best == nil || loc.score > best!.score {
                best = (loc.view, loc.score, "Locator")
            }
        }

        let threshold = igBoost ? 16 : 22
        guard let winner = best, winner.score >= threshold else {
            GlassDiagnostics.shared.recordInjection(
                score: best?.score ?? 0, host: best?.kind ?? "none",
                candidates: candidates, attached: false,
                note: "No host (attempt \(injectionAttempts))"
            )
            // Float early — especially LC
            let floatAt = GlassAppSupport.shared.isContainerEnvironment ? 2 : 3
            if injectionAttempts >= floatAt {
                if GlassAppSupport.shared.isContainerEnvironment {
                    prefs.forceShowGlassButton = true
                }
                ensureFloatingFallback()
            }
            return
        }

        removeFloatingFallback()
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
            btn.heightAnchor.constraint(equalToConstant: max(28, h)).isActive = true
            let targetIndex = min(4, stack.arrangedSubviews.count)
            stack.insertArrangedSubview(btn, at: targetIndex)
        } else {
            host.addSubview(btn)
            NSLayoutConstraint.activate([
                btn.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -10),
                btn.topAnchor.constraint(equalTo: host.topAnchor, constant: 6),
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
        DispatchQueue.main.async {
            let pt = btn.convert(btn.bounds.origin, to: nil)
            if pt.x > 0 && pt.y > 0 {
                GlassPreferences.shared.lastButtonPoint = pt
            }
        }
        GlassDiagnostics.shared.recordInjection(
            score: score, host: kind, candidates: 1, attached: true, note: "Injected \(kind)"
        )
        GlassPreferences.shared.log("Injected \(kind) score=\(score)")
        GlassStyleApplicator.applyAll()
    }

    // MARK: - Scan

    private static func scan(_ view: UIView, depth: Int,
                             best: inout (view: UIView, score: Int, kind: String)?,
                             count: inout Int, igBoost: Bool) {
        guard depth < 18 else { return }
        let name = NSStringFromClass(type(of: view))

        if let stack = view as? UIStackView, stack.axis == .horizontal {
            var s = scoreStack(stack, container: view.superview)
            if igBoost {
                let parent = view.superview.map { NSStringFromClass(type(of: $0)) } ?? ""
                if name.contains("Profile") || name.contains("Action") || parent.contains("Profile") {
                    s += 20
                }
            }
            if s >= 20 {
                count += 1
                if best == nil || s > best!.score { best = (stack, s, "Stack") }
            }
        }

        let buttons = view.subviews.filter { $0 is UIButton || $0 is UIControl }
        if buttons.count >= 2 && buttons.count <= 6 {
            var s = scoreButtonRow(buttons, in: view)
            if igBoost { s += 8 }
            if s >= 24 {
                count += 1
                if best == nil || s > best!.score {
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

        let hints = igBoost
            ? ["Profile", "Action", "ButtonBar", "EditProfile", "UserDetail", "Header"]
            : ["Toolbar", "Header", "Action", "NavBar", "TopBar"]
        if hints.contains(where: { name.contains($0) }) {
            if let stack = firstHorizontalStack(in: view) {
                let s = scoreStack(stack, container: view) + (igBoost ? 35 : 20)
                count += 1
                if best == nil || s > best!.score {
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
        guard controls.count >= 2, controls.count <= 6 else { return 0 }
        for v in stack.arrangedSubviews {
            if let lab = v as? UILabel {
                let s = (lab.text ?? "").lowercased()
                if s.contains("instagram") { return 0 }
            }
        }
        if stack.bounds.height > 72 { return 0 }
        var score = 20 + min(controls.count, 4) * 8
        if controls.count == 3 || controls.count == 4 { score += 16 }
        if stack.arrangedSubviews.count <= 6 { score += 6 }
        let cname = container.map { NSStringFromClass(type(of: $0)) } ?? ""
        if cname.contains("Navigation") || cname.contains("TabBar") { score -= 40 }
        if cname.contains("Profile") || cname.contains("Action") { score += 25 }
        return score
    }

    private static func scoreButtonRow(_ buttons: [UIView], in container: UIView) -> Int {
        let mids = buttons.map { $0.frame.midY }
        guard let first = mids.first else { return 0 }
        guard mids.allSatisfy({ abs($0 - first) < 18 }) else { return 8 }
        var score = 28 + buttons.count * 4
        let cname = NSStringFromClass(type(of: container))
        if cname.contains("Profile") || cname.contains("Action") { score += 20 }
        if cname.contains("Navigation") || cname.contains("TabBar") { score -= 35 }
        return score
    }

    private static func firstHorizontalStack(in view: UIView) -> UIStackView? {
        if let s = view as? UIStackView, s.axis == .horizontal { return s }
        for sub in view.subviews {
            if let f = firstHorizontalStack(in: sub) { return f }
        }
        return nil
    }

    // MARK: - Floating

    private static func ensureFloatingFallback() {
        if let f = floatingButton, f.superview != nil {
            attachedButton = f
            GlassDiagnostics.shared.recordInjection(
                score: 50, host: "FloatingReuse", candidates: 0, attached: true, note: "Floating reuse"
            )
            return
        }
        removeFloatingFallback()

        guard let window = GlassAppSupport.keyWindow()
                ?? GlassAppSupport.allWindows().first else {
            NSLog("[GlossyGlass] floating: no window")
            return
        }

        let btn = GlassSettingsButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(btn)

        // Bottom-trailing above tab island — never cover story tray / top chrome
        NSLayoutConstraint.activate([
            btn.trailingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            btn.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -72),
            btn.heightAnchor.constraint(equalToConstant: 32),
            btn.widthAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])

        let hold = GlassOpenSettingsLongPress()
        hold.cancelsTouchesInView = false
        btn.addGestureRecognizer(hold)

        floatingButton = btn
        attachedButton = btn
        GlassDiagnostics.shared.recordInjection(
            score: 50, host: "Floating", candidates: 0, attached: true, note: "Floating fallback"
        )
        NSLog("[GlossyGlass] Floating Glass button on window")
        GlassStyleApplicator.applyAll()
    }

    private static func removeFloatingFallback() {
        floatingButton?.removeFromSuperview()
        floatingButton = nil
    }

    private static func removeExistingButtons() {
        for window in GlassAppSupport.allWindows() {
            removeButtons(in: window)
        }
        removeFloatingFallback()
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

// MARK: - Gestures

private final class GlassOpenSettingsLongPress: UILongPressGestureRecognizer {
    init() {
        super.init(target: nil, action: nil)
        minimumPressDuration = 1.0
        addTarget(self, action: #selector(handled))
    }
    @objc private func handled() {
        guard state == .began else { return }
        if GlassPreferences.shared.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        GlassSettingsPresenter.present(from: view)
    }
}

private final class GlassGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = GlassGestureDelegate()
    func gestureRecognizer(_ g: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}
