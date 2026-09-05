import UIKit

/// Improved navigation & tab bar styling aiming for a more modern liquid-glass feel
@objc public class GlassNavigationHelper: NSObject {

    @objc public static func applyTabBarStyle(to tabBar: UITabBar) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled && prefs.styleTabBar else {
            prefs.log("TabBar styling skipped")
            return
        }

        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        let blurStyle: UIBlurEffect.Style = prefs.lightweightMode
            ? .systemUltraThinMaterial
            : (prefs.glassMode == 1 ? .systemThinMaterial : .systemMaterial)

        appearance.backgroundEffect = UIBlurEffect(style: blurStyle)
        appearance.backgroundColor = UIColor.clear
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()

        let item = UITabBarItemAppearance()
        item.normal.iconColor = UIColor.label.withAlphaComponent(0.40)
        item.selected.iconColor = .label

        let normalFont = UIFont.systemFont(ofSize: 10, weight: .medium)
        let selectedFont = UIFont.systemFont(ofSize: 10, weight: .semibold)

        item.normal.titleTextAttributes = [
            .foregroundColor: UIColor.label.withAlphaComponent(0.40),
            .font: normalFont
        ]
        item.selected.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: selectedFont
        ]

        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        // Soft floating shadow
        tabBar.clipsToBounds = false
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = prefs.lightweightMode ? 0.05 : 0.08
        tabBar.layer.shadowRadius = 18
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -4)

        // Continuous corners feel
        if #available(iOS 13.0, *) {
            tabBar.layer.cornerCurve = .continuous
        }

        prefs.log("TabBar style applied (mode \(prefs.glassMode))")
    }

    @objc public static func applyNavigationBarStyle(to navigationBar: UINavigationBar) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled && prefs.styleNavigationBar else {
            prefs.log("NavigationBar styling skipped")
            return
        }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()

        let blurStyle: UIBlurEffect.Style = prefs.lightweightMode
            ? .systemUltraThinMaterial
            : (prefs.glassMode == 1 ? .systemThinMaterial : .systemMaterial)

        appearance.backgroundEffect = UIBlurEffect(style: blurStyle)
        appearance.backgroundColor = UIColor.clear
        appearance.shadowColor = .clear

        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = .label

        prefs.log("NavigationBar style applied")
    }
}
