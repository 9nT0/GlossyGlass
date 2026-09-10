import UIKit

/// Styles native IG context menus / reaction bars / sheets when they appear.
/// Does not replace actions — only visual material on discovered surfaces.
@objc public final class GlassContextChrome: NSObject {

    @objc public static let shared = GlassContextChrome()

    private var observer: NSObjectProtocol?
    private var timer: Timer?
    private let materialTag = 0x4747_4358 // GGCX

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
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
                self?.scan()
            }
            self.scan()
        }
    }

    @objc public func scan() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }

        for w in GlassAppSupport.allWindows() {
            walk(w, depth: 0)
        }
    }

    private func walk(_ view: UIView, depth: Int) {
        guard depth < 16 else { return }
        let name = NSStringFromClass(type(of: view))
        let lower = name.lowercased()

        // Reaction bars, context menus, action sheets, plattters
        let isMenu =
            lower.contains("contextmenu")
            || lower.contains("uimenu")
            || lower.contains("actionsheet")
            || lower.contains("preview")
            || lower.contains("platter")
            || lower.contains("reaction")
            || lower.contains("emoji")
            || lower.contains("popover")
            || lower.contains("_uicontext")
            || lower.contains("uiglass")
            || (lower.contains("sheet") && view.bounds.height < 420 && view.bounds.width > 120)

        // Compact horizontal reaction-style bars
        let isReactionBar =
            view.bounds.height > 36 && view.bounds.height < 72
            && view.bounds.width > 180 && view.bounds.width < 420
            && view.layer.cornerRadius >= 12
            && (view.backgroundColor != nil || view is UIVisualEffectView)

        if isMenu || isReactionBar {
            applyGlass(to: view, compact: isReactionBar || view.bounds.height < 80)
        }

        // DM composer / input bar
        if lower.contains("composer") || lower.contains("inputtoolbar")
            || lower.contains("messageinput") || lower.contains("chatbar") {
            applyGlass(to: view, compact: true)
        }

        for s in view.subviews { walk(s, depth: depth + 1) }
    }

    private func applyGlass(to view: UIView, compact: Bool) {
        if view.viewWithTag(materialTag) != nil { return }
        // Don't touch if already a UIVisualEffectView we own elsewhere
        if view is GlassSettingsButton { return }

        let prefs = GlassPreferences.shared
        let effect = GlassMaterialEngine.shared.blurEffect(
            style: prefs.style,
            dark: true,
            intensity: max(0.55, prefs.intensity)
        )

        // Neutralize flat black fill
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
            view.layer.cornerRadius = min(22, max(14, view.bounds.height * 0.45))
            if #available(iOS 13.0, *) { view.layer.cornerCurve = .continuous }
            view.clipsToBounds = true
            blur.layer.cornerRadius = view.layer.cornerRadius
            blur.clipsToBounds = true
        }

        // Soft rim
        view.layer.borderWidth = 0.4
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.22 * prefs.intensity).cgColor

        // Raise content
        for sub in view.subviews where sub.tag != materialTag {
            view.bringSubviewToFront(sub)
        }
    }
}
