import UIKit

/// Optionally auto-applies stored per-screen presets when the visible UI changes.
@objc public class GlassScreenProfileMonitor: NSObject {

    private static var started = false
    private static var timer: Timer?
    private static var lastScreen: GlassScreen = .unknown

    @objc public static func start() {
        DispatchQueue.main.async {
            guard !started else { return }
            started = true
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                tick()
            }
        }
    }

    private static func tick() {
        let prefs = GlassPreferences.shared
        guard prefs.autoApplyScreenProfiles, prefs.isEnabled, !prefs.safeMode else { return }

        let screen = detectScreen()
        guard screen != .unknown, screen != lastScreen else { return }
        lastScreen = screen

        let name = prefs.profileName(for: screen)
        if name == "Off" {
            // Don't fully disable engine — just lightweight visuals optional
            return
        }
        // Apply preset without toggling master enable off
        prefs.applyPreset(name)
        prefs.log("Screen profile auto-applied: \(screen.rawValue) → \(name)")
    }

    private static func detectScreen() -> GlassScreen {
        // Walk key window titles / class names / tab selection heuristics
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            for window in ws.windows where window.isKeyWindow {
                if let hit = scan(window, depth: 0) { return hit }
                // Tab bar selected item
                if let tab = findTabBar(in: window) {
                    if let idx = tab.items?.firstIndex(of: tab.selectedItem ?? UITabBarItem()) {
                        // Common IG order: home, search, create, reels/shop, profile — messages often separate
                        let title = (tab.selectedItem?.title ?? tab.selectedItem?.accessibilityLabel ?? "").lowercased()
                        if title.contains("message") || title.contains("direct") { return .messages }
                        if title.contains("profile") { return .profile }
                        if title.contains("setting") { return .settings }
                        if idx == 0 { return .feed }
                    }
                }
            }
        }
        return .unknown
    }

    private static func scan(_ view: UIView, depth: Int) -> GlassScreen? {
        guard depth < 14 else { return nil }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if n.contains("direct") || n.contains("inbox") || n.contains("messagethread") { return .messages }
        if n.contains("profile") && n.contains("viewcontroller") { return .profile }
        if n.contains("settings") { return .settings }
        if n.contains("feed") || n.contains("home") { return .feed }
        for sub in view.subviews {
            if let s = scan(sub, depth: depth + 1) { return s }
        }
        return nil
    }

    private static func findTabBar(in view: UIView) -> UITabBar? {
        if let t = view as? UITabBar { return t }
        for sub in view.subviews {
            if let t = findTabBar(in: sub) { return t }
        }
        return nil
    }
}
