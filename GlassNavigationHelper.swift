import UIKit

/// Stronger liquid-glass NavigationBar + TabBar (v3.6.1 look pass)
@objc public class GlassNavigationHelper: NSObject {

    @objc public static func applyTabBarStyle(to tabBar: UITabBar) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled && prefs.styleTabBar else { return }

        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        let isDark = tabBar.traitCollection.userInterfaceStyle == .dark
        let blur: UIBlurEffect.Style
        if prefs.lightweightMode {
            blur = .systemUltraThinMaterial
        } else {
            blur = isDark ? .systemThinMaterialDark : .systemThinMaterialLight
        }

        if prefs.blurEnabled {
            appearance.backgroundEffect = UIBlurEffect(style: blur)
            appearance.backgroundColor = UIColor.white.withAlphaComponent(isDark ? 0.04 : 0.08)
        } else {
            appearance.backgroundEffect = nil
            appearance.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.92)
        }
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()

        let item = UITabBarItemAppearance()
        item.normal.iconColor = UIColor.label.withAlphaComponent(0.38)
        item.selected.iconColor = .label
        let fontN = UIFont.systemFont(ofSize: 10, weight: .medium)
        let fontS = UIFont.systemFont(ofSize: 10, weight: .semibold)
        item.normal.titleTextAttributes = [.foregroundColor: UIColor.label.withAlphaComponent(0.38), .font: fontN]
        item.selected.titleTextAttributes = [.foregroundColor: UIColor.label, .font: fontS]
        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.clipsToBounds = false
        tabBar.layer.cornerRadius = 26
        tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tabBar.layer.cornerCurve = .continuous
        tabBar.layer.borderWidth = 0.5
        tabBar.layer.borderColor = UIColor.white.withAlphaComponent(isDark ? 0.12 : 0.28).cgColor
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = prefs.lightweightMode ? 0.06 : 0.12
        tabBar.layer.shadowRadius = 20
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -3)
    }

    @objc public static func applyNavigationBarStyle(to navigationBar: UINavigationBar) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled && prefs.styleNavigationBar else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()

        let isDark = navigationBar.traitCollection.userInterfaceStyle == .dark
        let blur: UIBlurEffect.Style = prefs.lightweightMode
            ? .systemUltraThinMaterial
            : (isDark ? .systemMaterialDark : .systemMaterialLight)

        if prefs.blurEnabled {
            appearance.backgroundEffect = UIBlurEffect(style: blur)
            appearance.backgroundColor = UIColor.white.withAlphaComponent(isDark ? 0.05 : 0.10)
        } else {
            appearance.backgroundEffect = nil
            appearance.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.94)
        }
        appearance.shadowColor = .clear

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
        navigationBar.layer.cornerCurve = .continuous
        // Soft bottom edge highlight
        navigationBar.layer.shadowColor = UIColor.black.cgColor
        navigationBar.layer.shadowOpacity = prefs.lightweightMode ? 0.04 : 0.08
        navigationBar.layer.shadowRadius = 12
        navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2)
    }
}
