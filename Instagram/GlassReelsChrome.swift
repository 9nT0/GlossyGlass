import UIKit

/// Reels + Stories chrome
@objc public final class GlassReelsChrome: NSObject {
    @objc public static let shared = GlassReelsChrome()

    @objc public func apply(in window: UIView) {
        let prefs = GlassPreferences.shared
        guard prefs.styleReels else { return }

        // Reels bottom actions / side actions
        let reels = IGLocator.shared.findViews(classContains: "reel", in: window)
            + IGLocator.shared.findViews(classContains: "clips", in: window)

        for v in reels {
            let n = NSStringFromClass(type(of: v)).lowercased()
            if n.contains("action") || n.contains("button") || n.contains("toolbar") || n.contains("footer") {
                if v.bounds.height > 30 && v.bounds.height < 120 {
                    GlassMaterial.shared.apply(to: v, style: .soft, corner: 16)
                    if prefs.animations { GlassAnimations.shared.attachPress(to: v) }
                }
            }
        }

        // Stories tray / ring containers
        let stories = IGLocator.shared.findViews(classContains: "story", in: window)
            + IGLocator.shared.findViews(classContains: "stories", in: window)

        for v in stories {
            if v.bounds.height > 50 && v.bounds.height < 140 {
                // Soft treatment only — don’t break the story rings
                if prefs.glossyMode {
                    v.layer.cornerCurve = .continuous
                }
                if prefs.animations && (v is UIControl || v is UIButton) {
                    GlassAnimations.shared.attachPress(to: v)
                }
            }
        }

        // Viewer chrome (top bar when watching a story/reel)
        let viewers = IGLocator.shared.findViews(classContains: "viewer", in: window)
            + IGLocator.shared.findViews(classContains: "playback", in: window)

        for v in viewers {
            if v.bounds.height > 36 && v.bounds.height < 90 {
                GlassMaterial.shared.apply(to: v, style: .soft, corner: 0)
            }
        }
    }
}
