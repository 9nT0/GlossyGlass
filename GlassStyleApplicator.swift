import UIKit

/// Buttons / cards only. Tab bar + nav bar are owned by GlassUICoordinator
/// (GlassDock / GlassNavChrome). Do not paint full-width slabs here.
@objc public final class GlassStyleApplicator: NSObject {

    @objc public static let shared = GlassStyleApplicator()
    private var started = false
    private var lastPass: TimeInterval = 0

    @objc public static func start() {
        shared.begin()
    }

    private func begin() {
        guard !started else { return }
        started = true
        // Light delayed pass for buttons/cards only
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.applyButtonsAndCards()
        }
    }

    @objc public func apply() {
        applyButtonsAndCards()
    }

    private func applyButtonsAndCards() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastPass < 0.5 { return }
        lastPass = now

        // Intentionally does NOT walk UITabBar / UINavigationBar.
        // Those are handled by GlassDock and GlassNavChrome via the coordinator.
        guard prefs.styleButtons || prefs.styleCards else { return }

        for w in GlassAppSupport.allWindows() {
            walkControls(w, depth: 0)
        }
    }

    private func walkControls(_ view: UIView, depth: Int) {
        guard depth < 10 else { return }

        // Hard skip chrome owners and media
        if view is UITabBar || view is UINavigationBar { return }
        if GlassMediaExclusion.shouldSkipGlass(for: view) { return }
        let n = NSStringFromClass(type(of: view)).lowercased()
        if n.contains("igtabbar") || n.contains("ignavigationbar") { return }
        if view is UICollectionView || view is UITableView { return }

        let prefs = GlassPreferences.shared

        if prefs.styleButtons, view is UIButton || n.contains("igbutton") {
            let f = view.bounds
            if f.width > 28, f.height > 28, f.width < 200, f.height < 56 {
                // Subtle continuous corner only — no full glass plate on every button
                view.layer.cornerRadius = min(prefs.cornerRadius, f.height * 0.45)
                if #available(iOS 13.0, *) { view.layer.cornerCurve = .continuous }
            }
        }

        for s in view.subviews {
            walkControls(s, depth: depth + 1)
        }
    }
}
