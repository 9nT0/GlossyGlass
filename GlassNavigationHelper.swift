import UIKit

/// Real liquid-glass chrome for UINavigationBar + UITabBar.
/// Edge-to-edge materials — no floating “box” overlays on the bar itself.
@objc public class GlassNavigationHelper: NSObject {

    @objc public static func applyNavigationBarStyle(to navigationBar: UINavigationBar) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, prefs.styleNavigationBar, !prefs.safeMode else { return }

        let isDark = navigationBar.traitCollection.userInterfaceStyle == .dark
        let intensity = effectiveIntensity(isDark: isDark, prefs: prefs)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()

        if prefs.blurEnabled && !UIAccessibility.isReduceTransparencyEnabled {
            let style = blurStyle(isDark: isDark, prefs: prefs)
            appearance.backgroundEffect = UIBlurEffect(style: style)
            // Slight tint so it reads as glass, not empty
            let alpha = (isDark ? 0.06 : 0.10) * intensity * prefs.opacity
            appearance.backgroundColor = UIColor.white.withAlphaComponent(min(0.22, alpha))
        } else {
            appearance.backgroundEffect = nil
            appearance.backgroundColor = UIColor.secondarySystemBackground
                .withAlphaComponent(0.88 * prefs.opacity)
        }

        let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: titleFont
        ]
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
        // NO cornerRadius on full-width nav — that creates the “box overlay” look
        navigationBar.layer.cornerRadius = 0
        navigationBar.layer.maskedCorners = []
        navigationBar.layer.borderWidth = 0
        navigationBar.layer.shadowOpacity = 0
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()

        // Hairline glass edge under bar
        installBottomHairline(on: navigationBar, isDark: isDark, intensity: intensity)
    }

    @objc public static func applyTabBarStyle(to tabBar: UITabBar) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, prefs.styleTabBar, !prefs.safeMode else { return }

        // Stock bar is interaction-only. Visual chrome is GlassLiquidTabBar capsule.
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()

        let item = UITabBarItemAppearance()
        let fontN = UIFont.systemFont(ofSize: 10, weight: .medium)
        let fontS = UIFont.systemFont(ofSize: 10, weight: .semibold)
        item.normal.iconColor = UIColor.label.withAlphaComponent(0.55)
        item.selected.iconColor = .label
        item.normal.titleTextAttributes = [
            .foregroundColor: UIColor.label.withAlphaComponent(0.55),
            .font: fontN
        ]
        item.selected.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: fontS
        ]
        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = true
        tabBar.backgroundColor = .clear
        tabBar.barTintColor = .clear
        tabBar.layer.cornerRadius = 0
        tabBar.layer.borderWidth = 0
        tabBar.layer.shadowOpacity = 0
        // Keep hit targets; liquid capsule is drawn above as visual only
    }

    // MARK: - Helpers

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
        default: // Frosted
            return isDark ? .systemThinMaterialDark : .systemThinMaterialLight
        }
    }

    private static let hairlineTag = 0x4747_484C // "GGHL"

    private static func installBottomHairline(on bar: UIView, isDark: Bool, intensity: CGFloat) {
        bar.viewWithTag(hairlineTag)?.removeFromSuperview()
        let line = UIView()
        line.tag = hairlineTag
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = UIColor.white.withAlphaComponent(isDark ? 0.10 * intensity : 0.22 * intensity)
        bar.addSubview(line)
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            line.bottomAnchor.constraint(equalTo: bar.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale)
        ])
    }
}
