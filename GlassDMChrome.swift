import UIKit

/// DM header + composer glass only. Never covers message text or media.
@objc public final class GlassDMChrome: NSObject {

    @objc public static let shared = GlassDMChrome()
    private let composerTag = 0x4747_444D // GGDM

    @objc public func apply() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        for w in GlassAppSupport.allWindows() {
            walk(w, depth: 0)
        }
    }

    private func walk(_ view: UIView, depth: Int) {
        guard depth < 14 else { return }
        if GlassMediaExclusion.shouldSkipGlass(for: view) { return }

        let n = NSStringFromClass(type(of: view)).lowercased()
        if n.contains("composer") || n.contains("inputtoolbar")
            || n.contains("messageinput") || n.contains("chatbar") {
            styleComposer(view)
        }
        // DM nav is handled by GlassNavChrome (small capsules)
        for s in view.subviews { walk(s, depth: depth + 1) }
    }

    private func styleComposer(_ view: UIView) {
        if view.viewWithTag(composerTag) != nil { return }
        if view is UIVisualEffectView {
            if let fx = view as? UIVisualEffectView {
                fx.effect = GlassMaterialEngine.shared.blurEffect(
                    style: GlassPreferences.shared.style, dark: true, intensity: 0.6
                )
            }
            return
        }
        view.backgroundColor = .clear
        let prefs = GlassPreferences.shared
        let _ = GlassBubbleKit.installBubble(
            into: view,
            tag: composerTag,
            frame: view.bounds,
            style: prefs.style,
            intensity: prefs.intensity,
            opacity: prefs.opacity
        )
        if let b = view.viewWithTag(composerTag) {
            b.frame = view.bounds
            b.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            b.layer.cornerRadius = min(22, view.bounds.height * 0.45)
        }
        for sub in view.subviews where sub.tag != composerTag {
            view.bringSubviewToFront(sub)
        }
    }
}
