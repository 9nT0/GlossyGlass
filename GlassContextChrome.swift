import UIKit

/// Styles native IG context menus / reaction bars when they appear.
/// Never nests UIVisualEffectView inside UIVisualEffectView (UIKit throws).
@objc public final class GlassContextChrome: NSObject {

    @objc public static let shared = GlassContextChrome()

    private var observer: NSObjectProtocol?
    private var timer: Timer?
    private let materialTag = 0x4747_4358 // GGCX
    private let tintTag = 0x4747_4359

    private override init() { super.init() }

    @objc public func start() {
        DispatchQueue.main.async {
            if self.observer == nil {
                self.observer = NotificationCenter.default.addObserver(
                    forName: UIWindow.didBecomeVisibleNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in self?.scan() }
            }
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                self?.scan()
            }
            self.scan()
        }
    }

    @objc public func scan() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        for w in GlassAppSupport.allWindows() {
            stripFromMedia(w, depth: 0)
            walk(w, depth: 0)
        }
    }

    /// Remove any GG material we may have put on a video surface.
    private func stripFromMedia(_ view: UIView, depth: Int) {
        guard depth < 16 else { return }
        if GlassMediaExclusion.shouldSkipGlass(for: view) || GlassMediaExclusion.matches(view) {
            for sub in view.subviews {
                if sub.tag == materialTag || sub.tag == tintTag || sub.tag == 0x4747_4D41
                    || sub.tag == 0x4747_494E || sub.tag == 0x4747_4358 {
                    sub.removeFromSuperview()
                }
            }
        }
        for s in view.subviews { stripFromMedia(s, depth: depth + 1) }
    }

    private func walk(_ view: UIView, depth: Int) {
        guard depth < 14 else { return }
        // Never recurse into our own material or into effect content carelessly
        if view.tag == materialTag || view.tag == tintTag { return }

        let name = NSStringFromClass(type(of: view))
        let lower = name.lowercased()

        // Skip our chrome plates
        if view.tag == 0x4747_4D41 || view.tag == 0x4747_504C { return }

        let isMenu =
            lower.contains("contextmenu")
            || lower.contains("actionsheet")
            || lower.contains("platter")
            || lower.contains("reaction")
            || lower.contains("_uicontext")
            || lower.contains("popover")
        // intentionally NO "preview" — matches video preview containers

        let isReactionBar =
            view.bounds.height > 36 && view.bounds.height < 72
            && view.bounds.width > 180 && view.bounds.width < 420
            && view.layer.cornerRadius >= 12

        let isComposer =
            lower.contains("composer") || lower.contains("inputtoolbar")
            || lower.contains("messageinput") || lower.contains("chatbar")

        if isMenu || isReactionBar || isComposer {
            // Never cover video / 1v / 2v / DM media viewers
            if GlassMediaExclusion.shouldSkipGlass(for: view) { return }
            applyGlass(to: view, compact: isReactionBar || view.bounds.height < 80)
        }

        for s in view.subviews {
            // Do not walk into UIVisualEffectView.contentView children for applying
            // but still walk siblings
            walk(s, depth: depth + 1)
        }
    }

    private func applyGlass(to view: UIView, compact: Bool) {
        if view.viewWithTag(materialTag) != nil { return }
        if view is GlassSettingsButton { return }
        if GlassMediaExclusion.shouldSkipGlass(for: view) { return }

        let prefs = GlassPreferences.shared
        let effect = GlassMaterialEngine.shared.blurEffect(
            style: prefs.style,
            dark: true,
            intensity: max(0.55, prefs.intensity)
        )

        // CRITICAL: never add UIVisualEffectView as subview of UIVisualEffectView
        if let existing = view as? UIVisualEffectView {
            existing.effect = effect
            existing.alpha = max(0.88, prefs.opacity)
            if compact {
                existing.layer.cornerRadius = min(22, max(14, existing.bounds.height * 0.45))
                if #available(iOS 13.0, *) { existing.layer.cornerCurve = .continuous }
                existing.clipsToBounds = true
            }
            // Tint goes on contentView only
            addTint(to: existing.contentView, intensity: prefs.intensity)
            return
        }

        view.backgroundColor = .clear
        view.isOpaque = false

        let blur = UIVisualEffectView(effect: effect)
        blur.tag = materialTag
        blur.isUserInteractionEnabled = false
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blur, at: 0)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if compact {
            let r = min(22, max(14, view.bounds.height * 0.45))
            view.layer.cornerRadius = r
            if #available(iOS 13.0, *) { view.layer.cornerCurve = .continuous }
            view.clipsToBounds = true
            blur.layer.cornerRadius = r
            blur.clipsToBounds = true
        }

        view.layer.borderWidth = 0.4
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.22 * prefs.intensity).cgColor

        addTint(to: blur.contentView, intensity: prefs.intensity)

        for sub in view.subviews where sub.tag != materialTag {
            view.bringSubviewToFront(sub)
        }
    }

    private func addTint(to contentView: UIView, intensity: CGFloat) {
        if contentView.viewWithTag(tintTag) != nil { return }
        let tint = UIView()
        tint.tag = tintTag
        tint.isUserInteractionEnabled = false
        tint.backgroundColor = UIColor.white.withAlphaComponent(0.12 * intensity)
        tint.translatesAutoresizingMaskIntoConstraints = false
        contentView.insertSubview(tint, at: 0)
        NSLayoutConstraint.activate([
            tint.topAnchor.constraint(equalTo: contentView.topAnchor),
            tint.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tint.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tint.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
