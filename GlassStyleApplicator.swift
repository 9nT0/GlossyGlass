import UIKit

/// Applies real glass materials to Instagram / host chrome — not decorative overlays.
@objc public class GlassStyleApplicator: NSObject {

    private static var started = false
    private static var timer: Timer?
    private static var observer: NSObjectProtocol?

    @objc public static func start() {
        DispatchQueue.main.async {
            if !started {
                started = true
                observer = NotificationCenter.default.addObserver(
                    forName: .glassPreferencesDidChange,
                    object: nil,
                    queue: .main
                ) { _ in applyAll() }

                // Frequent while settling, then steady
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                    applyAll()
                }
                for d in [0.3, 0.8, 1.5, 3.0, 6.0, 12.0] as [TimeInterval] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + d) { applyAll() }
                }
            }
            applyAll()
        }
    }

    @objc public static func applyAll() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }

        for window in GlassAppSupport.allWindows() {
            walk(window, depth: 0)
        }
    }

    private static func walk(_ view: UIView, depth: Int) {
        guard depth < 24 else { return }
        let prefs = GlassPreferences.shared

        if let nav = view as? UINavigationBar, prefs.styleNavigationBar {
            GlassNavigationHelper.applyNavigationBarStyle(to: nav)
        }
        if let tab = view as? UITabBar, prefs.styleTabBar {
            GlassNavigationHelper.applyTabBarStyle(to: tab)
        }

        // Instagram often uses custom header containers instead of UINavigationBar
        if prefs.styleNavigationBar {
            tryStyleCustomHeader(view)
        }

        if prefs.styleCards {
            applyCardIfLikely(view)
        }
        if prefs.styleButtons, let btn = view as? UIButton, !(btn is GlassSettingsButton) {
            applyButtonChrome(btn)
        }

        for sub in view.subviews {
            walk(sub, depth: depth + 1)
        }
    }

    /// Soft glass on IG-like top chrome (search bars, custom nav containers).
    private static func tryStyleCustomHeader(_ view: UIView) {
        let name = NSStringFromClass(type(of: view))
        let lower = name.lowercased()
        let looksHeader =
            lower.contains("navbar") || lower.contains("navigationbar") ||
            lower.contains("header") || lower.contains("topbar") ||
            lower.contains("searchbar") || lower.contains("ignavigation")

        guard looksHeader else { return }
        // Only wide, short strips near the top
        guard view.bounds.width > 200, view.bounds.height > 28, view.bounds.height < 120 else { return }
        // Skip our own glass button
        if view is GlassSettingsButton { return }

        let prefs = GlassPreferences.shared
        let isDark = view.traitCollection.userInterfaceStyle == .dark

        // Prefer adding a blur behind existing content once
        let blurTag = 0x4747_424C // "GGBL"
        if view.viewWithTag(blurTag) == nil, prefs.blurEnabled,
           !UIAccessibility.isReduceTransparencyEnabled {
            let style: UIBlurEffect.Style = isDark ? .systemThinMaterialDark : .systemThinMaterialLight
            let blur = UIVisualEffectView(effect: UIBlurEffect(style: style))
            blur.tag = blurTag
            blur.translatesAutoresizingMaskIntoConstraints = false
            blur.isUserInteractionEnabled = false
            view.insertSubview(blur, at: 0)
            NSLayoutConstraint.activate([
                blur.topAnchor.constraint(equalTo: view.topAnchor),
                blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                blur.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        // Soft edge, continuous curve only if already rounded
        if view.layer.cornerRadius >= 8 {
            view.layer.cornerCurve = .continuous
            if prefs.edgeHighlightEnabled, view.layer.borderWidth < 0.2 {
                view.layer.borderWidth = 0.4
                view.layer.borderColor = UIColor.white
                    .withAlphaComponent(isDark ? 0.12 : 0.22).cgColor
            }
        }

        // Knock down opaque backgrounds so blur shows through
        if let bg = view.backgroundColor, bg.cgColor.alpha > 0.85 {
            view.backgroundColor = bg.withAlphaComponent(0.15)
        }
    }

    private static func applyButtonChrome(_ button: UIButton) {
        let title = ((button.title(for: .normal) ?? button.currentTitle ?? "")
            + " " + (button.accessibilityLabel ?? "")).lowercased()
        let blocked = ["follow", "following", "message", "share", "like", "comment",
                       "post", "send", "reply", "story", "reels", "live", "subscribe"]
        if blocked.contains(where: { title.contains($0) }) { return }
        if button.bounds.width > 160 && button.bounds.height > 40 { return }

        if button.layer.cornerRadius < 1 { button.layer.cornerRadius = 10 }
        button.layer.cornerCurve = .continuous
        if button.backgroundColor == nil || button.backgroundColor == .clear {
            let isDark = button.traitCollection.userInterfaceStyle == .dark
            button.backgroundColor = UIColor.white.withAlphaComponent(isDark ? 0.08 : 0.12)
        }
        button.clipsToBounds = true
    }

    private static func applyCardIfLikely(_ view: UIView) {
        let name = NSStringFromClass(type(of: view))
        let looksCard = name.contains("Cell") || name.contains("Card") || name.contains("Collection")
            || (view.bounds.height > 60 && view.bounds.width > 120 && view.layer.cornerRadius >= 8)
        guard looksCard else { return }
        guard view.backgroundColor != nil || view.layer.cornerRadius > 0 else { return }
        if view is UIControl || view is UIButton { return }

        view.layer.cornerCurve = .continuous
        if view.layer.cornerRadius < 8 { view.layer.cornerRadius = 14 }
        if view.layer.borderWidth < 0.2 {
            let isDark = view.traitCollection.userInterfaceStyle == .dark
            view.layer.borderWidth = 0.4
            view.layer.borderColor = UIColor.white.withAlphaComponent(isDark ? 0.10 : 0.18).cgColor
        }
    }
}
