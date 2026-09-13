import UIKit

/// In-place liquid materials for UINavigationBar + UITabBar.
/// No extra subviews, no hairlines, no floating boxes.
@objc public class GlassNavigationHelper: NSObject {

    @objc public static func applyNavigationBarStyle(to navigationBar: UINavigationBar) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, prefs.styleNavigationBar, !prefs.safeMode else {
            restoreNavigationBar(navigationBar)
            return
        }
        // Mutual exclusion with tab emphasis when both toggled — still apply both materials,
        // but nav stays edge-to-edge (no island), tab stays full system bar with glass fill.

        let isDark = navigationBar.traitCollection.userInterfaceStyle == .dark
        let intensity = effectiveIntensity(isDark: isDark, prefs: prefs)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()

        if prefs.blurEnabled && !UIAccessibility.isReduceTransparencyEnabled {
            appearance.backgroundEffect = GlassLiquidEngine.shared.blurEffectMatchingPreferences(dark: isDark)
            let a = (isDark ? 0.04 : 0.08) * intensity * prefs.opacity
            appearance.backgroundColor = UIColor.white.withAlphaComponent(min(0.18, a))
        } else {
            appearance.backgroundEffect = nil
            appearance.backgroundColor = UIColor.secondarySystemBackground
                .withAlphaComponent(0.92 * prefs.opacity)
        }

        let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label, .font: titleFont]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = appearance
        }

        navigationBar.isTranslucent = true
        navigationBar.barTintColor = .clear
        navigationBar.backgroundColor = .clear
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()

        // Clean — no corner box, no hairline subviews, no borders
        navigationBar.layer.cornerRadius = 0
        navigationBar.layer.maskedCorners = []
        navigationBar.layer.borderWidth = 0
        navigationBar.layer.shadowOpacity = 0
        stripTagged(from: navigationBar)
    }

    @objc public static func applyTabBarStyle(to tabBar: UITabBar) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, prefs.styleTabBar, !prefs.safeMode else {
            restoreTabBar(tabBar)
            return
        }

        let isDark = tabBar.traitCollection.userInterfaceStyle == .dark
        let intensity = effectiveIntensity(isDark: isDark, prefs: prefs)

        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()

        if prefs.blurEnabled && !UIAccessibility.isReduceTransparencyEnabled {
            appearance.backgroundEffect = GlassLiquidEngine.shared.blurEffectMatchingPreferences(dark: isDark)
            let a = (isDark ? 0.05 : 0.09) * intensity * prefs.opacity
            appearance.backgroundColor = UIColor.white.withAlphaComponent(min(0.20, a))
        } else {
            appearance.backgroundEffect = nil
            appearance.backgroundColor = UIColor.secondarySystemBackground
                .withAlphaComponent(0.94 * prefs.opacity)
        }

        let item = UITabBarItemAppearance()
        let fontN = UIFont.systemFont(ofSize: 10, weight: .medium)
        let fontS = UIFont.systemFont(ofSize: 10, weight: .semibold)
        item.normal.iconColor = UIColor.white.withAlphaComponent(0.48)
        item.selected.iconColor = UIColor.white
        // Hide titles — icon-only glass tab look
        item.normal.titleTextAttributes = [
            .foregroundColor: UIColor.clear, .font: fontN
        ]
        item.selected.titleTextAttributes = [
            .foregroundColor: UIColor.clear, .font: fontS
        ]
        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = true
        tabBar.backgroundColor = .clear
        tabBar.barTintColor = .clear

        // Full-width glass bar — not a floating island overlay
        tabBar.layer.cornerRadius = 0
        tabBar.layer.borderWidth = 0
        tabBar.layer.shadowOpacity = 0
        tabBar.alpha = 1
        stripTagged(from: tabBar)
    }

    // MARK: - Restore / helpers

    private static func restoreNavigationBar(_ bar: UINavigationBar) {
        let a = UINavigationBarAppearance()
        a.configureWithDefaultBackground()
        bar.standardAppearance = a
        bar.scrollEdgeAppearance = a
        stripTagged(from: bar)
    }

    private static func restoreTabBar(_ bar: UITabBar) {
        let a = UITabBarAppearance()
        a.configureWithDefaultBackground()
        bar.standardAppearance = a
        bar.scrollEdgeAppearance = a
        bar.alpha = 1
        stripTagged(from: bar)
    }

    private static func stripTagged(from view: UIView) {
        for sub in view.subviews {
            if sub.tag == 0x4747_484C || sub.tag == 0x4747_424C || sub.tag == 0x4747_5442 {
                sub.removeFromSuperview()
            }
        }
    }

    private static func effectiveIntensity(isDark: Bool, prefs: GlassPreferences) -> CGFloat {
        let base = isDark ? prefs.darkIntensity : prefs.lightIntensity
        return max(0.15, min(1.0, base * prefs.intensity))
    }

    private static func blurStyle(isDark: Bool, prefs: GlassPreferences) -> UIBlurEffect.Style {
        if prefs.lightweightMode {
            return isDark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
        }
        switch prefs.style.lowercased() {
        case "clear":
            return isDark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
        case "tinted":
            return isDark ? .systemMaterialDark : .systemMaterialLight
        default:
            return isDark ? .systemThinMaterialDark : .systemThinMaterialLight
        }
    }
}
